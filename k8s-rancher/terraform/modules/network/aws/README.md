# network

```
Internet
    ↕
Internet Gateway (IGW)
    ↕
Public Subnet (10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24)
├── NAT Gateway (has EIP)
    ↕
Private Subnet (10.0.101.0/24, 10.0.102.0/24, 10.0.103.0/24)
├── App Servers (no public IP)
├── Database (no public IP)
├── Internal Services (no public IP)
```
