# Split Big Files  
---
By @yanshiqwq  
一个将大文件分割为多个指定大小小文件的 shell 脚本.  
特点:  
    1.  无损分割, 分割过程没有数据丢失  
    2.  不限格式, 可以分割任何文件  
    3.  使用 MD5 校验分割前的原始文件和分割后的文件块, 保证在传输过程中的数据安全  
    4.  会将分割时的部分信息记录至日志  
    5.  分割速度取决于硬盘I/O速度极限 (分割时) 和CPU计算速度 (计算校验值时)  
推荐使用方式:  
    1.  搭配 Git Bash 或 WSL 在 Windows 系统上使用  
    2.  将大文件分割为小文件绕过 mover.io 等网站的单文件大小限制  