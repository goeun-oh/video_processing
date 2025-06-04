import pygame
import cv2
import numpy as np

# 초기화
pygame.init()
screen = pygame.display.set_mode((320, 240))
clock = pygame.time.Clock()
font = pygame.font.SysFont(None, 48)

# 가상 카메라 프레임
camera_frame = np.zeros((240, 320, 3), dtype=np.uint8)

# 공 설정
ball_x, ball_y = 160, 120
ball_radius = 5
ball_speed_x, ball_speed_y = 2, -2
gravity = 0.2

# Paddle 설정
paddle_width = 6
paddle_height = 40
paddle_x = 160
paddle_y = 100

# 게임 상태
lose = False

running = True
while running:
    # ===== Paddle 위치 마우스로 제어 =====
    mouse_x, mouse_y = pygame.mouse.get_pos()

    camera_frame[:] = 0
    cv2.rectangle(camera_frame, (mouse_x - 15, mouse_y - 20), (mouse_x + 15, mouse_y + 20), (255, 255, 255), -1)

    hsv = cv2.cvtColor(camera_frame, cv2.COLOR_BGR2HSV)
    white_mask = cv2.inRange(hsv, np.array([0, 0, 200]), np.array([180, 30, 255]))
    contours, _ = cv2.findContours(white_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    if contours:
        largest = max(contours, key=cv2.contourArea)
        M = cv2.moments(largest)
        if M['m00'] > 0:
            cx = int(M['m10'] / M['m00'])
            cy = int(M['m01'] / M['m00'])
            paddle_x = cx - paddle_width // 2
            paddle_y = cy - paddle_height // 2

    # 이벤트 처리
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
        if lose and event.type == pygame.KEYDOWN and event.key == pygame.K_SPACE:
            ball_x, ball_y = 160, 120
            ball_speed_x, ball_speed_y = 2, -2
            lose = False

    if not lose:
        # 공 위치 업데이트
        ball_x += ball_speed_x
        ball_y += ball_speed_y
        ball_speed_y += gravity

        # 바닥 반사
        if ball_y + ball_radius > 240:
            ball_y = 240 - ball_radius
            ball_speed_y = -abs(ball_speed_y) * 0.8

        # 천장 반사
        if ball_y - ball_radius < 0:
            ball_y = ball_radius
            ball_speed_y = abs(ball_speed_y)

        # 왼쪽 벽 반사
        if ball_x - ball_radius < 0:
            ball_x = ball_radius
            ball_speed_x = abs(ball_speed_x)

        # 오른쪽 벽 → 게임 오버
        if ball_x + ball_radius > 320:
            lose = True

        # Paddle 충돌 처리
        if (paddle_x < ball_x + ball_radius < paddle_x + paddle_width) and \
           (paddle_y < ball_y < paddle_y + paddle_height):
            # 즉시 Paddle 밖으로 튕겨나가도록 위치 보정
            ball_x = paddle_x - ball_radius - 1

            # 튕겨나가는 강한 반사 적용
            ball_speed_x = -max(4, abs(ball_speed_x) * 1.2)
            ball_speed_y = -abs(ball_speed_y) * 0.9

    # 화면 렌더링
    screen.fill((0, 0, 0))
    pygame.draw.rect(screen, (255, 255, 255), (paddle_x, paddle_y, paddle_width, paddle_height))
    pygame.draw.circle(screen, (255, 0, 0), (int(ball_x), int(ball_y)), ball_radius)

    if lose:
        text = font.render("Lose", True, (255, 0, 0))
        text_rect = text.get_rect(center=(160, 120))
        screen.blit(text, text_rect)

    pygame.display.flip()
    clock.tick(60)

pygame.quit()
