# 💥 Aegis-Stress: Bộ Kịch Bản Tấn Công & Đánh Giá Tường Lửa Hạt Nhân (eBPF/XDP)

Bộ công cụ kiểm thử xâm nhập (Penetration Testing) và đánh giá độ bền (Stress Test) sử dụng **`hping3`**, được thiết kế để chạy trực tiếp trên máy ảo **Kali Linux Attacker (VM 106 - `172.30.0.202`)** nhằm bắn phá và kích hoạt các cơ chế loại bỏ gói tin (Drop Rules) tại tầng nhân của **Aegis-KernelFW (Gateway `172.30.0.101`)**.

---

## ❓ Câu hỏi kỹ thuật: "Kernel có Anti được ReDoS không?"

### ❌ Trả lời ngắn: **KHÔNG. Kernel eBPF/XDP không thể trực tiếp chống ReDoS.**

### 🔍 Giải thích bản chất kỹ thuật:
1. **ReDoS (Regular Expression Denial of Service) là tấn công Tầng Ứng Dụng (Layer 7 Semantic Attack):**
   * Kẻ tấn công gửi một chuỗi đầu vào được tính toán kỹ lưỡng (ví dụ: `aaaaaaaaaaaaaaaaaaaaaaaaaaaa!`) vào các API nhận dữ liệu (Email, Username, Search query).
   * Chuỗi này khiến bộ phân tích biểu thức chính quy (Regex Engine) có thuật toán quay lui (Catastrophic Backtracking) trong mã nguồn ứng dụng (Node.js, Python, Java, Go, PHP) bị rơi vào vòng lặp hàm mũ $O(2^n)$, vắt kiệt 100% CPU của Web/API Server.
2. **Tại sao tầng Kernel (L3/L4 eBPF/XDP) không thể nhận diện ReDoS?**
   * **Gói tin hoàn toàn hợp lệ về mặt mạng:** Gói tin ReDoS mang đầy đủ IP Header chuẩn, TCP 3-Way Handshake chuẩn, cờ ACK hợp lệ, checksum đúng, độ dài gói tin bình thường và thường được mã hóa qua TLS/HTTPS (cổng 443).
   * **Giới hạn của eBPF trong Linux Kernel:** eBPF chạy tại Driver mạng với ràng buộc nghiêm ngặt từ bộ kiểm tra an toàn (BPF Verifier) — không cho phép vòng lặp vô hạn, không cấp phát bộ nhớ tùy ý, và không thể giải mã TLS để bóc tách ngữ nghĩa JSON/HTTP Body phức tạp.
3. **Cách chống ReDoS chuẩn mực:**
   * **Tại tầng Ứng dụng (Application Code):** 
     * Thay thế Regex engine backtracking bằng Regex tuyến tính $O(N)$ (ví dụ: Google RE2, Rust `regex`).
     * Đặt giới hạn độ dài ký tự đầu vào (`max_length <= 255`).
     * Thiết lập Timeout cho việc khớp Regex (Regex Evaluation Timeout).
   * **Tại tầng WAF / Reverse Proxy (Lớp 4):** Sử dụng Nginx / Cloudflare / WAF để chặn các payload có độ dài bất thường.
   * **Vai trò hỗ trợ gián tiếp của Kernel:** Nếu kẻ tấn công dùng botnet gửi hàng ngàn request ReDoS cùng lúc (High PPS), **Method 10 (Dynamic Auto-Ban)** của eBPF sẽ khóa IP đó do vượt ngưỡng tần suất gói tin, nhưng nếu chỉ 1 request đơn lẻ gây ReDoS thì bắt buộc Lớp 4 (Application) phải tự xử lý.

---

## 🎯 8 Kịch Bản Tấn Công Trọng Tâm Bằng `hping3` (Kèm Counter Theo Dõi Trên Kernel)

Bộ kịch bản ưu tiên các dạng **sai cấu hình header, sai cờ TCP, bất thường IP và flood lưu lượng** để làm nổi bật các bộ đếm Drop trên Kernel:

| Bài Test | Tên Kịch Bản | Lệnh `hping3` Cốt Lõi | Cơ Chế Kernel XDP Drop | Metric Monitor Trên Kernel |
| :---: | :--- | :--- | :--- | :--- |
| **01** | **Land Attack & Bogon IP** | `hping3 -S -a 172.30.0.101 -p 80 172.30.0.101` | **Method 02**: Drop gói tin có `Src IP == Dst IP` hoặc Bogon IP (`127.0.0.1/8`, `0.0.0.0/8`). | `STAT_DROPPED_BOGON` |
| **02** | **Invalid TCP Flags** | `hping3 --null -p 80 172.30.0.101`<br>`hping3 --xmas -p 80 172.30.0.101`<br>`hping3 -S -F -p 80 172.30.0.101` | **Method 04**: Drop các tổ hợp cờ quét trinh sát bất thường (Null scan, Xmas, SYN-FIN, SYN-RST, FIN lẻ). | `STAT_DROPPED_TCP_FLAGS` |
| **03** | **IP Fragmentation** | `hping3 -S -f -p 80 -d 120 172.30.0.101` | **Method 03**: Bắt cờ phân mảnh `IP_MF=1` hoặc `Offset > 0` và drop triệt để tại Inbound. | `STAT_DROPPED_FRAGMENTED` |
| **04** | **High-PPS SYN Flood & Ban** | `hping3 --flood -S -p 80 172.30.0.101`<br>`hping3 --flood -S --rand-source -p 80 172.30.0.101` | **Method 05 & 10**: Vượt sliding window SYN rate limit; Token bucket tự động đẩy IP vào bảng phạt `map_dynamic_ban`. | `STAT_DROPPED_SYN_FLOOD`<br>`STAT_DROPPED_DYNAMIC_BAN` |
| **05** | **Out-of-State ACK Flood** | `hping3 -A -p 9999 172.30.0.101` | **Method 06**: Drop các gói ACK gửi vào cổng đóng không thuộc session hợp lệ, chống nghẽn CPU kernel sinh gói RST. | `STAT_DROPPED_OUT_OF_STATE` |
| **06** | **UDP Closed Port Flood** | `hping3 --udp -p 54321 -d 64 172.30.0.101` | **Method 07**: Drop các gói UDP gửi tới port không mở trong `map_open_udp_ports`, dập tắt bão ICMP port unreachable. | `STAT_DROPPED_UDP_JUNK` |
| **07** | **ICMP Ping Flood** | `hping3 --icmp -i u2000 172.30.0.101` | **Method 08**: Token bucket rate limit cờ Echo Request (type 8), chống nghẽn đường truyền ICMP. | `STAT_DROPPED_ICMP_FLOOD` |
| **08** | **TCP Zero-Window Anomaly** | `hping3 -S -p 80 --win 0 172.30.0.101` | **Method 13**: Drop gói tin mang Window size = 0 có ý đồ đóng băng socket buffer máy chủ (Sockstress). | `STAT_DROPPED_TCP_ANOMALY` |

---

## 🚀 Hướng Dẫn Sử Dụng Trực Tiếp Trên Kali Linux (VM 106)

### 1. Khởi chạy Menu Giao Diện Tương Tác
```bash
cd /root/aegis-stress
sudo bash aegis_stress.sh
```

### 2. Chạy nhanh từng bài test qua dòng lệnh (CLI):
```bash
# Chạy Test 01: Land Attack
sudo bash scripts/01_test_malformed_land.sh 172.30.0.101 80 100

# Chạy Test 02: Invalid TCP Flags (Null / Xmas / SYN-FIN)
sudo bash scripts/02_test_tcp_invalid_flags.sh 172.30.0.101 80 100

# Chạy Test 03: IP Fragmentation
sudo bash scripts/03_test_ip_fragmentation.sh 172.30.0.101 80 150

# Chạy Test 04: SYN Flood trong 10 giây
sudo bash scripts/04_test_syn_flood.sh 172.30.0.101 80 10

# Chạy tự động toàn bộ 8 bài test liên tiếp:
sudo bash aegis_stress.sh --all
```

---

## 📡 Cách Monitor Drop Counters Trên Kernel Firewall (Node 172.30.0.101)

Mở một cửa sổ Terminal thứ hai SSH vào máy chủ **Kernel Firewall Gateway** và chạy một trong các lệnh sau để quan sát số gói bị Drop nhảy số thời gian thực:

```bash
# Cách 1: Xem Dashboard Live Telemetry (Tự động làm mới mỗi giây)
cd /mnt/d/project/Aegis-KernelFW
sudo ./build/aegis-fw stats --live

# Cách 2: In bảng thống kê chi tiết từng Method
sudo ./build/aegis-fw stats

# Cách 3: Kiểm tra danh sách các IP đang bị giam phạt trong eBPF Auto-Ban Map
sudo ./build/aegis-fw map dump map_dynamic_ban

# Cách 4: Đọc trực tiếp từ kernel dmesg
sudo dmesg -w | grep -i --color=auto -E 'xdp|bpf|aegis'
```
