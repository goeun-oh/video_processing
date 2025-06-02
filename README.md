# QVGA Ball Linear Motion System

이 프로젝트는 Python과 Pygame을 사용해 QVGA(320x240) 해상도에서  
패들(Paddle)로 공(Ball)을 막는 직선 이동 게임을 구현한 것입니다.  
최종적으로 FPGA 연동 및 OV7670 카메라 입력으로 확장할 계획을 염두에 두고 설계했습니다.

---

## 🔑 핵심 기능

- QVGA (320x240) 화면 맞춤
- 패들(Paddle)을 위/아래로 움직여 공을 막음
- 공이 패들에 못 닿으면 "Lose" 메시지 출력
- 스페이스바로 게임 재시작

---

## ▶ 실행 방법

1️⃣ Jupyter Notebook을 통한 Python 코드 입력
2️⃣ Pygame 설치: pip install pygame   
3️⃣ 아래 코드를 `pong_qvga.py`로 저장   
4️⃣ 터미널에서 실행


---

## 🏗 전체 코드

```python
import pygame

# Pygame 초기화 및 QVGA 화면 설정
pygame.init()
screen = pygame.display.set_mode((320, 240))  # QVGA (320x240)
clock = pygame.time.Clock()
font = pygame.font.SysFont(None, 48)  # 메시지용 폰트

# Paddle(패들) 변수 설정
paddle_width = 6
paddle_height = 40
paddle_x = 320 - paddle_width - 20  # 오른쪽 끝에서 20px 띄움
paddle_y = 100
paddle_speed = 3

# Ball(공) 변수 설정
ball_x = 160
ball_y = 120
ball_radius = 5
ball_speed_x = -2  # 왼쪽에서 출발
ball_speed_y = 0

# Lose 상태 플래그
lose = False

running = True
while running:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False

        # Lose 상태에서 스페이스바로 재시작
        if lose and event.type == pygame.KEYDOWN:
            if event.key == pygame.K_SPACE:
                ball_x = 160
                ball_y = 120
                ball_speed_x = -2
                lose = False

    if not lose:
        # 키 입력 처리 (위/아래 화살표)
        keys = pygame.key.get_pressed()
        if keys[pygame.K_UP]:
            paddle_y -= paddle_speed
        if keys[pygame.K_DOWN]:
            paddle_y += paddle_speed

        # Paddle이 화면 밖으로 나가지 않게 제한
        if paddle_y < 0:
            paddle_y = 0
        if paddle_y > 240 - paddle_height:
            paddle_y = 240 - paddle_height

        # 공 이동
        ball_x += ball_speed_x

        # Paddle에 공이 닿으면 방향 반전
        if (paddle_x < ball_x + ball_radius < paddle_x + paddle_width) and (paddle_y < ball_y < paddle_y + paddle_height):
            ball_speed_x = -ball_speed_x

        # 왼쪽 벽에 닿으면 방향 반전
        if ball_x < 0 + ball_radius:
            ball_speed_x = -ball_speed_x

        # 오른쪽 벽 넘어가면 Lose
        if ball_x > 320:
            lose = True

    # 화면 그리기
    screen.fill((0, 0, 0))  # 배경
    pygame.draw.rect(screen, (255, 255, 255), (paddle_x, paddle_y, paddle_width, paddle_height))  # Paddle
    pygame.draw.circle(screen, (255, 0, 0), (int(ball_x), int(ball_y)), ball_radius)  # Ball

    # Lose 메시지 출력
    if lose:
        text = font.render('Lose', True, (255, 0, 0))
        text_rect = text.get_rect(center=(160, 120))
        screen.blit(text, text_rect)

    pygame.display.flip()
    clock.tick(60)  # 초당 60프레임

pygame.quit()
