# 버전 1
## I2C Master (왼쪽 보드 부분)
### 코드
[I2C Interface 버전 1](./I2C_Intf_V00.sv)  
단순하게 공의 좌표, 속도만을 `전송`만 하는 Interface  
- [I2C Controller](./I2C_Controller.sv)  
    I2C 전송을 관리하는 Controller
- [I2C Master](./I2C_Master.sv)  
    전송을 쉽게 하기 위해 READ 관련 STATE 삭제


### 개략 설명
Master(왼쪽 보드)는 Slave(오른쪽 보드) 에게  

1) 공의 y 좌표  
2) y 방향으로의 속도를 전송함 (`x 방향 속도도 추후 전송해줘야할듯 ㅠㅠ`)

따라서 다음과 같은 설정 값이 필요
1. I2C Slave의 Address
2. I2C Slave의 Register Address

따라서, I2C Slave Register 는 다음과 같이 구성
| Register 이름 | 용도               | 비트수 | 비고             |
|---------------|--------------------|--------|------------------|
| `slv_reg0`    | 공의 y 좌표 저장   | 2bit  | 추후 x좌표 추가 예정 |
| `slv_reg1`    | 공의 y 좌표 저장   | 8bit  | 추후 x좌표 추가 예정 |
| `slv_reg2`    | 공의 y 방향 속도   | 8bit | 부호 포함        |

## I2C SLAVE (오른쪽 보드 부분)
### 코드
[I2C Slave code](./SLAVE/I2C_Slave.sv)

### 개략 설명
기존 `i2c_slave`모듈에서 수신 만 정해진 시나리오대로 가능 하도록 대폭 수정 필요.

즉, 개략적인 전송 순서는

IDLE -> START -> ADDR -> ACK ->  SLV0_DATA0 -> ACK -> SLV0_DATA1 -> ACK -> ...

통신이 끝나고 나면 slv_reg0과 slv_reg1을 모아서 공의 y좌표 register로 재설정 필요


## 시뮬 & 테스트
가장 초기 테스트로는 I2C Master와 Interface를 build up 하고 다른 보드에는 I2C Slave를 bitstream download하여 정해진 register에 정해진 값을 저장하는지만 확인 할 것.

