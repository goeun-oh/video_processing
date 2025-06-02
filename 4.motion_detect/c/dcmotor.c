#include "main.h"


extern TIM_HandleTypeDef htim3;

uint8_t pwm_start_flag = 0;
uint16_t pwm_value = 0;
void dcmotor_pwm_control(void);

void dcmotor_pwm_control(void)
{
	/*
	// start / stop
	if (get_button(GPIOC, GPIO_PIN_5, BUTTON0) == BUTTON_PRESS)
	{
		HAL_GPIO_TogglePin(LED0_GPIO_Port, GPIO_PIN_0);
		if (!pwm_start_flag)
		{
			HAL_TIM_PWM_Stop(&htim3, TIM_CHANNEL_1);
		}
		else
		{
			HAL_TIM_PWM_Start(&htim3, TIM_CHANNEL_1);
		}
		pwm_start_flag =!pwm_start_flag;
	}
	// speed-up
	if (get_button(GPIOC, GPIO_PIN_6, BUTTON1) == BUTTON_PRESS)
	{
		HAL_GPIO_TogglePin(LED0_GPIO_Port, GPIO_PIN_1);
		pwm_value = __HAL_TIM_GET_COMPARE(&htim3, TIM_CHANNEL_1);
		pwm_value += 10;
		if (pwm_value > 100) pwm_value = 100;
		__HAL_TIM_SET_COMPARE(&htim3, TIM_CHANNEL_1, pwm_value);

	}
	// speed-down
	if (get_button(GPIOC, GPIO_PIN_8, BUTTON2) == BUTTON_PRESS)
	{
		HAL_GPIO_TogglePin(LED0_GPIO_Port, GPIO_PIN_2);
		pwm_value = __HAL_TIM_GET_COMPARE(&htim3, TIM_CHANNEL_1);
		pwm_value -= 10;
		if (pwm_value < 70) pwm_value = 70;
		__HAL_TIM_SET_COMPARE(&htim3, TIM_CHANNEL_1, pwm_value);
	}
	*/
}
