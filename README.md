# 점수 시스템 구현
# 왼쪽 Player가 Win인 경우
상대 player 화면의 오른쪽 벽에 닿아야 win
이 정보-> 오른쪽이 줌 -> 오른쪽 마스터가 줘야됨

Register 하나 더 생성
Register score[msb: lose정보]

Lose 정보는 졌을때 1, 아니면 그냥 0
Lose 정보는 그냥 1 bit flag 밖에 안됨
그리고 기존에 정보 전송하는 것과 경우가 다름

### [오른쪽 Player : I2C Master에서 전송해야하는 정보들]
1. 왼쪽 벽에 맞을 경우: 
- 전송 정보: 속도 등 총 5개 레지스터 정보 전송
- 조건: `game_controller.sv` 모듈의 `RUNNING_RIGHT` -> `end else if (ball_x_out >= (upscale ? 640 - 20 : 320 - 20)) begin` 에서 전송
- flag: `send_lose_information`

2. 오른쪽 벽에 맞을 경우:
1개 레지스터 정보 (`Lose flag`)만 전송
- 조건: `game_controller.sv` 모듈의 `RUNNING_LEFT` -> `if (ball_x_out <= 0) begin` 에서 전송, 이후 `SEND_BALL`로 천이
- flag: `ball_send_triger_next`




## 왼쪽 벽에 맞을 경우
### 오른쪽 Player 입장: I2C Controller 수정
I2C Controller input으로 `send_lose_information` 추가


** 기존 `game_controller.sv` 에서 `slave_register_addr`를 전송하는 STATE 하나 더 추가**
```c
    //기존 STATE
    IDLE,
    START_WAIT,
    WAIT,
    SEND_DATA,
    STOP,
    DONE

    //바뀐 STATE
    IDLE,
    START_WAIT,
    WAIT,
    SEND_ADDR,
    SEND_DATA,
    SEND_LOSE_DATA,
    STOP,
    DONE
```

> 1. 오른쪽 Player에서 왼쪽 Player로 Lose 정보를 전송하는 것 까지는 완료.
> 2. 왼쪽 Player에서 Lose 정보를 받았을 때 어떻게할지 정해야함


### 왼쪽 Player 입장: I2C Slave 수정
I2C Slave에서 slv_addr를 받는 STATE를 추가해주어야함 (완료)
받았으면? `game_controller.sv`에서 해당 flag를 가져와서 처리해줘야함
