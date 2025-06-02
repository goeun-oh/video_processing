# video_processing

import pygame

pygame.init()
screen = pygame.display.set_mode((320, 240))  # QVGA 해상도
clock = pygame.time.Clock()
font = pygame.font.SysFont(None, 48)  # 화면이 작으니 글자 크기 축소

# Paddle 변수
paddle_width = 6
paddle_height = 40
paddle_x = 320 - paddle_width - 20  # 오른쪽 끝에서 20px 띄움
paddle_y = 100
paddle_speed = 3

# Ball 변수
ball_x = 160
ball_y = 120
ball_radius = 5
ball_speed_x = -2
ball_speed_y = 0

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
        keys = pygame.key.get_pressed()
        if keys[pygame.K_UP]:
            paddle_y -= paddle_speed
        if keys[pygame.K_DOWN]:
            paddle_y += paddle_speed

        # Paddle 화면 경계 제한
        if paddle_y < 0:
            paddle_y = 0
        if paddle_y > 240 - paddle_height:
            paddle_y = 240 - paddle_height

        # 공 이동
        ball_x += ball_speed_x

        # Paddle 충돌 체크
        if (paddle_x < ball_x + ball_radius < paddle_x + paddle_width) and (paddle_y < ball_y < paddle_y + paddle_height):
            ball_speed_x = -ball_speed_x

        # 왼쪽 벽에 닿으면 반전
        if ball_x < 0 + ball_radius:
            ball_speed_x = -ball_speed_x

        # 오른쪽 벽 넘어가면 Lose
        if ball_x > 320:
            lose = True

    # 화면 그리기
    screen.fill((0, 0, 0))
    pygame.draw.rect(screen, (255, 255, 255), (paddle_x, paddle_y, paddle_width, paddle_height))
    pygame.draw.circle(screen, (255, 0, 0), (int(ball_x), int(ball_y)), ball_radius)

    if lose:
        text = font.render('Lose', True, (255, 0, 0))
        text_rect = text.get_rect(center=(160, 120))
        screen.blit(text, text_rect)

    pygame.display.flip()
    clock.tick(60)

pygame.quit()
