# 버전 1
## I2C Master (왼쪽 보드 부분)
### 코드
[I2C Interface 버전 1](../MASTER/I2C_Intf_V00.sv)  
단순하게 공의 좌표, 속도만을 `전송`만 하는 Interface  
- [I2C Controller](../MASTER/I2C_Controller.sv)  
    I2C 전송을 관리하는 Controller
- [I2C Master](../MASTER/I2C_Master.sv)  
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
[I2C Slave code](../SLAVE/I2C_Slave.sv)

### 개략 설명
기존 `i2c_slave`모듈에서 수신 만 정해진 시나리오대로 가능 하도록 대폭 수정 필요.

즉, 개략적인 전송 순서는

IDLE -> START -> ADDR -> ACK ->  SLV0_DATA0 -> ACK -> SLV0_DATA1 -> ACK -> ...

통신이 끝나고 나면 slv_reg0과 slv_reg1을 모아서 공의 y좌표 register로 재설정 필요


## 시뮬 & 테스트
1) 가장 초기 테스트로는 I2C Master와 Interface를 build up 하고 다른 보드에는 I2C Slave를 bitstream download하여 정해진 register에 정해진 값을 저장하는지만 확인 할 것.  

-> 확인 완료, 정상 동작

# 버전 2
왼쪽 화면의 공이 오른쪽 화면으로 기존 포물선 운동을 유지하며 운동하는 것 까지 구현

I2C Slave Register 는 다음과 같이 구성됨
## I2C Slave Reigster Map
| Register 이름 | 용도               | 비트수 | 비고             |
|---------------|--------------------|--------|------------------|
| `slv_reg0`    | 공의 y 좌표 저장   | 2bit  | 추후 x좌표 추가 예정 |
| `slv_reg1`    | 공의 y 좌표 저장   | 8bit  | 추후 x좌표 추가 예정 |
| `slv_reg2`    | 공의 y 방향 속도   | 8bit | 부호 포함        |
| `slv_reg3`    | gravity   | 2bit |         |
| `slv_reg4`    | safe speed   | 8bit | 공의 speed 를 유지하기 위해 safe speed를 가져오고, ball speed를 이로 나눈 값으로 적용하기 위해 필요함        |


## 트러블 및 해결
### 1. I2C 통신으로 왼쪽 공의 좌표값 등은 잘 전송 되나 오른쪽 화면의 공의 움직임이 이상하거나, 멈추는 현상
**[현상]**  
- 왼쪽 공이 멈춘 y 좌표에 오른쪽 공이 멈추기는 하나
- 오른쪽 공이 움직이지 않고 정지해있음 -> 확인해 보니 IDLE 상태에 계속 stuck 됨

**[원인]**  
오른쪽 보드의 `game_controller.sv` 모듈에서 IDLE -> RUNNING_RIGHT 로 천이하는 코드
```systemVerilog
  IDLE: begin
    LED = 8'b0000_0001;
    game_over_next = 0;
    score_test_next = 0;
    safe_speed_next = 1;
    is_idle = 1'b1;
    if (go_right) begin
        next = RUNNING_RIGHT;
        ball_y_next = {slv_reg0_y0[7:6], slv_reg1_y1};
        ball_x_next = 20;
        ball_y_vel_next = slv_reg2_Yspeed;
        gravity_counter_next = slv_reg3_gravity[1:0];
        safe_speed_next = (slv_reg4_ballspeed == 8'd0) ? 1: slv_reg4_ballspeed;
        ball_speed_next = 20'd270000 / safe_speed_next;
    end
```
`go_right`신호는 I2C SLAVE가 MASTER 로 부터 데이터를 모두 전송 받은 후(STOP state에서) `game_controller.sv` 모듈에 주는 신호.
I2C SLAVE의 CLK은 `100MHz`주기, game controller CLK은 `25MHz`주기
따라서 game controller가 `go_right`를 catch 하지 못할 가능성이 존재

**[해결]**.  
I2C 에서 'go_right'신호를 game controller가 받았다는 signal 을 보내기 전까지 유지하게 함
