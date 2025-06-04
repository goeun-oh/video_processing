import pygame

# Pygame 초기화 및 QVGA 화면 설정
pygame.init()
screen = pygame.display.set_mode((320, 240))  # QVGA 해상도
clock = pygame.time.Clock()
font = pygame.font.SysFont(None, 48)

# Paddle 변수 설정
paddle_width = 6
paddle_height = 40
paddle_x = 320 - paddle_width - 20  # 오른쪽 가장자리에서 20px 안쪽
paddle_y = 100
paddle_speed = 3

# Ball 변수 설정
ball_radius = 5
ball_x = 160
ball_y = 120
ball_speed_x = +2      # 공을 오른쪽으로 시작
ball_speed_y = -2      # 위쪽으로 발사
gravity = 0.2          # 포물선 궤적을 만들 중력 가속도
restitution = 0.8     # 바닥/천장 충돌 시 반사 탄성 계수

# Lose 상태
lose = False

# 게임 루프 시작
running = True
while running:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False

        # 패배 상태에서 스페이스바로 재시작
        if lose and event.type == pygame.KEYDOWN:
            if event.key == pygame.K_SPACE:
                ball_x = 160
                ball_y = 120
                ball_speed_x = +2
                ball_speed_y = -2
                lose = False

    if not lose:
        # 키 입력 처리
        keys = pygame.key.get_pressed()
        if keys[pygame.K_UP]:
            paddle_y -= paddle_speed
        if keys[pygame.K_DOWN]:
            paddle_y += paddle_speed

        # Paddle 위치 제한
        if paddle_y < 0:
            paddle_y = 0
        if paddle_y > 240 - paddle_height:
            paddle_y = 240 - paddle_height

        # 공 위치 업데이트
        ball_x += ball_speed_x
        ball_y += ball_speed_y
        ball_speed_y += gravity  # 중력 효과 적용

        # Paddle 충돌 감지
        if (paddle_x < ball_x + ball_radius < paddle_x + paddle_width) and \
           (paddle_y < ball_y < paddle_y + paddle_height):
            ball_speed_x = -abs(ball_speed_x)  # 왼쪽으로 튕기기
            ball_speed_y = -abs(ball_speed_y)  # 위로 튕기기

        # 바닥에 닿았을 때
        if ball_y + ball_radius > 240:
            ball_y = 240 - ball_radius
            ball_speed_y = -abs(ball_speed_y) * restitution  # 아래에서 위로 튕김

        # 천장에 닿았을 때
        if ball_y - ball_radius < 0:
            ball_y = ball_radius
            ball_speed_y = abs(ball_speed_y) * restitution

        # 왼쪽 벽 충돌
        if ball_x - ball_radius < 0:
            ball_x = ball_radius
            ball_speed_x = abs(ball_speed_x)  # 오른쪽으로 튕김

        # 오른쪽 벽 넘어가면 게임 오버
        if ball_x > 320:
            lose = True

    # 화면 렌더링
    screen.fill((0, 0, 0))  # 배경
    pygame.draw.rect(screen, (255, 255, 255), (paddle_x, paddle_y, paddle_width, paddle_height))  # Paddle
    pygame.draw.circle(screen, (255, 0, 0), (int(ball_x), int(ball_y)), ball_radius)  # Ball

    # 패배 시 메시지 출력
    if lose:
        text = font.render('Lose', True, (255, 0, 0))
        text_rect = text.get_rect(center=(160, 120))
        screen.blit(text, text_rect)

    pygame.display.flip()
    clock.tick(60)  # FPS

pygame.quit()
