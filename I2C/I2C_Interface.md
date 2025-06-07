# 버전 1 (6/6)
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

# 버전 2 (6/8)
## 기능 구현 목표:
왼쪽 화면의 공이 기존의 포물선 운동을 유지한 채 오른쪽 화면으로 자연스럽게 이동하는 동작 구현 

### 전체 시스템 흐름
1. 공이 왼쪽 보드에서 포물선 운동 중 오른쪽 벽에 도달하면 `ball_send_trigger` 발생
2. `I2C_Controller`는 해당 신호를 받아 공의 y좌표, 속도, 중력 등을 전송
3. I2C Master → I2C Slave로 정보 전달 완료되면 `go_right` 발생
4. 오른쪽 보드의 `game_controller`가 해당 신호를 받아 공 운동 재시작

I2C Slave Register 는 다음과 같이 구성됨

## I2C Slave Reigster Map
| Register 이름 | 용도               | 비트수 | 비고             |
|---------------|--------------------|--------|------------------|
| `slv_reg0`    | 공의 y 좌표 저장   | 2bit  | |
| `slv_reg1`    | 공의 y 좌표 저장   | 8bit  |  |
| `slv_reg2`    | 공의 y 방향 속도   | 8bit | 부호 포함        |
| `slv_reg3`    | gravity   | 2bit |         |
| `slv_reg4`    | safe speed   | 8bit | 공의 speed 를 유지하기 위해 safe speed를 가져오고, ball speed를 이로 나눈 값으로 적용하기 위해 필요함        |

## 시뮬 & 테스트
- **조건:**  
  - 왼쪽 화면에서 공이 오른쪽 벽에 도달할 때 `ball_send_trigger`가 발생  
  - I2C Master가 공의 y좌표, y속도, 중력값, safe_speed를 전송  

- **검증 절차:**  
  - 오른쪽 보드에서 I2C Slave가 해당 값을 수신 후 공 운동 재개  
  - 공이 왼쪽 보드의 y좌표에서 시작하여 동일한 속도와 궤적으로 포물선 운동을 하는지 확인  
  - 궤적 일치 여부를 시각적으로 확인 (양쪽 화면 비교)

## 트러블 및 해결
### 1. 오른쪽 보드에서 공이 멈춘 상태로 움직이지 않는 현상

**[현상]**  
- 왼쪽 공이 오른쪽으로 넘어간 후, 오른쪽 보드의 공이 y좌표 위치까지는 이동하지만 더 이상 움직이지 않고 정지함  
- 내부적으로 `game_controller` 모듈이 `IDLE` 상태에서 `RUNNING_RIGHT` 상태로 전이되지 않고 **stuck**됨을 확인함


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
go_right 신호는 I2C Slave가 Master로부터 모든 데이터를 수신하고 STOP 상태에 도달한 이후 발생시킴
그러나 I2C Slave는 100MHz 클럭으로 동작하고, game_controller는 25MHz로 동작하여
클럭 도메인 차이로 인해 go_right가 너무 짧게 발생하면 game_controller가 해당 신호를 잡지 못하고 놓치는 현상 발생

**[해결]**.  
I2C 에서 'go_right'신호를 game controller가 받았다는 signal 을 보내기 전까지 유지하게 함

- Handshake 기반 CDC 처리. 
`I2C Slave`와 `game_controller`는 서로 다른 클럭 도메인에서 동작하므로, 단발성 신호(`pulse`)만으로는 안정적인 상태 전달이 어려움.  
이를 해결하기 위해 **레벨 기반의 handshake 방식**을 적용함.

- 동작 흐름. 

1. `I2C FSM`에서 모든 데이터를 전송한 후, `go_right` 신호를 1로 설정하고 **유지**
2. `game_controller`는 FSM에서 `go_right`가 high일 때 `IDLE → RUNNING_RIGHT`로 전이, I2C에 go right signal을 정상적으로 받았다는 flag전송
3. `I2C FSM`은 `game_controller`에게서 해당 flag를 수신 후
   **FSM을 IDLE로 되돌리고 `go_right`를 0으로 클리어**

이를 통해 **신호 손실 없이 안정적으로 데이터 수신 타이밍을 보장**

> 이 구조는 clock domain crossing (CDC) 환경에서 흔히 사용하는 handshake 기법이며,  
> signal loss 방지, 신뢰성 향상, 타이밍 정합성 측면에서 매우 효과적임