#include "main.h"
extern TIM_HandleTypeDef htim2;
extern TIM_HandleTypeDef htim11;

// 예시 delay_us(10); ==> 10us 동안 wait
void delay_us(int us);

// interrupt call back function(interrupt service routine이라고 한다.)
// interrupt 내부에 서는 변수는 최적화 방지를 위해서 변수 type앞에
// volatile이라고 선언 한다.
volatile int TIM11_1ms_counter=0;

volatile int TIM11_1ms_ds1302=0;
volatile int TIM11_1ms_stopwatch=0;

// Driver/STM32F4xx_HAL_Driver/src/stm32f4xx_hal_tim.c 에서 move
// timer interrupt가 뜰때 마다 이곳으로 자동적으로 들어 온다.
// ---- 예) tim11 인경우 1ms마다 이곳으로 진입 한다. ----
// - system clock : 84MHZ
// - prescale : 84, - counter period: 1000
// T = 1/f  1/1000000HZ = 0.000001Sec(1us) : 1개의 펄스 소요시간
// 1us * 1000 ==> 1ms
// interrupt call back function은 가능한 짧게 구현 한다.
void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim)
{
	if (htim->Instance == TIM11)  // ADD_JOON
	{
		TIM11_1ms_counter++;
		TIM11_1ms_ds1302++;
		TIM11_1ms_stopwatch++;
	}
}

// ADD sjkim 24.11.18
// 1MHz 분주 주파수가 TIM2으로 입력된다.
// 한 주기 T = 1/f = 1/1000000Hz ==> 0.000001sec (1us): 1개의 펄스 소요 시간
// 예) delay_us(1000) --> 1ms 동안 wait
void delay_us(int us)
{
	__HAL_TIM_SET_COUNTER(&htim2, 0); // timer2번의 counter를 초기화 시켜준다. (0부터 시작해야하니)

	//사용자가 지정한 us동안 머물러 있도록 한다.
	while(__HAL_TIM_GET_COUNTER(&htim2) < us)
	{
		; // No Operation 빙글빙글
	}
}
