# Ultimate LEGENDARY Tunnel Engine 🚀

**Author:** Erfan Esmizadh  
**GitHub:** [ultimate-legend](https://github.com/erfanesmizadh/ultimate-legend)  

---

## 🔥 توضیحات پروژه

این پروژه یک **Tunnel Engine سطح LEGENDARY** برای کاربران ایران و خارج است که شامل:

- Multi WireGuard Tunnel با **Load Balancing و Failover خودکار**  
- Xray Reality / VLESS Inbound و Freedom Outbound با **Least-Latency Routing**  
- Health Check خودکار برای **قطع نشدن Tunnel ها**  
- Kernel Optimization: **BBR + fq_codel + TX tuning**  
- Bash Menu حرفه‌ای برای **مدیریت Tunnel ها و Routing**  

این اسکریپت برای **500 تا 2000+ concurrent users** بهینه شده و پایدار است.

---

## ⚡ نیازمندی‌ها

- سرور ایران با Public IP  
- سرورهای خارج (Foreign) با Public IP و WireGuard فعال  
- Ubuntu/Debian 20+ یا هر توزیع سازگار با WireGuard  
- دسترسی root یا sudo  

---

## 🛠️ نصب و راه‌اندازی (سرور ایران)

1. **کلون پروژه:**

```bash
git clone https://github.com/erfanesmizadh/ultimate-legend.git
cd ultimate-legend
اجازه اجرا به اسکریپت:
Copy code
Bash
chmod +x install.sh
اجرای اسکریپت نصب:
Copy code
Bash
bash install.sh
Interactive Config:
از شما سوال می‌شود:
IP ایران (IRAN_PUBLIC_IP)
تعداد tunnels (سرورهای خارجی)
IP و PublicKey هر Tunnel
شما می‌توانید قبل ادامه setup با nano فایل‌های main.conf و tunnels.conf را ویرایش کنید.
WireGuard tunnels و routing به صورت خودکار ساخته می‌شوند
Health Check هر دقیقه اجرا می‌شود و Tunnel خراب خودکار غیرفعال می‌شود.
Bash Menu مدیریت Tunnel ها:
پس از نصب، منوی زیر باز می‌شود:
Copy code

1) Show WireGuard Status
2) Restart a Tunnel
3) Bring Down a Tunnel
4) Bring Up a Tunnel
5) Show Routing Table
6) Edit main.conf
7) Edit tunnels.conf
0) Exit
می‌توانید Tunnel ها را مدیریت کنید و تنظیمات config را ویرایش کنید.
🛠️ راه‌اندازی روی سرورهای خارجی
روی هر سرور خارجی، WireGuard نصب کنید:
Copy code
Bash
apt update
apt install -y wireguard
برای هر Tunnel یک Keypair تولید کنید:
Copy code
Bash
wg genkey | tee private.key | wg pubkey > public.key
PublicKey هر Tunnel را هنگام اجرای اسکریپت ایران وارد کنید.
سرور خارجی باید firewall مناسب داشته باشد تا پورت WireGuard باز باشد (51820+ برای هر Tunnel).
🔧 فایل‌ها و مسیرها
Copy code

ultimate-legend/
│
├─ install.sh         # اسکریپت اصلی setup + menu
├─ config/
│   ├─ main.conf       # IRAN_PUBLIC_IP و سایر تنظیمات اصلی
│   └─ tunnels.conf    # FOREIGN_IP و PUBLIC_KEY هر Tunnel
└─ README.md
main.conf و tunnels.conf قابل ویرایش با nano هستند و تغییرات خودکار در setup اعمال می‌شود.
⚡ ویژگی‌ها
Multi WireGuard Tunnel با MTU بهینه (1280)
Auto Health Check و Failover
Kernel Multipath Routing برای Load Balance واقعی
Adaptive Congestion Control (BBR + fq_codel)
Least-Latency Xray Outbound (برای اجرای Xray بعدی آماده)
Reality / VLESS fragmentation برای Anti-DPI
Bash Menu برای مدیریت Tunnel ها و مشاهده Routing
⚠️ نکات مهم
MTU هر Tunnel = 1280 برای جلوگیری از fragmentation
Xray outbound باید دارای fwmark=255 باشد تا Policy Routing اعمال شود
Cron Health Check هر دقیقه Tunnel ها را بررسی می‌کند
مناسب برای تعداد بالای concurrent users (500-2000+)
📝 License
MIT License © 2026 Erfan Esmizadh
