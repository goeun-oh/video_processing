#include "led.h"

void led_main(void);
void led_left_on(void);
void led_right_on(void);
void led_left_keepon(void);
void led_right_keepon(void);
void led_flower_on(void);
void led_flower_off(void);

void on_led(int led_number);
void off_led(int led_number);
void on_led(int led_number);
void off_led(int led_number);

void led_all_on (void);
void led_all_off (void);


int func_index=-1;
void (*funcp[])() =
{
	 led_all_on,   // 0
	 led_all_off,   // 1
	 led_left_on ,  //2
	 led_right_on,  //3
	 led_flower_on,  //4
	 led_flower_off,  //5
	 led_left_keepon,  //6
	 led_right_keepon  //7
};

extern void button_check(void);
extern void pc_command_processing(void);
extern void dht11(void);
extern void ultrasonic_processing();

extern volatile int TIM11_1ms_counter;
extern void delay_us(int us);



// none os 또는 loop monitor방식
void led_main(void)
{

	while(1)
	{
//		button_check();
//		pc_command_processing();
//		dht11();
//		ultrasonic_processing();

	}
}

void led_flower_on(void)
{
#if 0
	static int i=0;

	if (TIM11_1ms_counter >= 100)
	{
		TIM11_1ms_counter=0;

		if (i < 4)
		{
			HAL_GPIO_WritePin(GPIOB, 0x10 << i | 0x08 >> i , 1);
		}
		if (++i >= 5)
		{
			i=0;
			HAL_GPIO_WritePin(GPIOB, 0xff, 0);
		}
	}
#endif
#if 0
	static int i=0;

	if (i < 4)
	{
		HAL_GPIO_WritePin(GPIOB, 0x10 << i | 0x08 >> i , 1);
		HAL_Delay(100);
	}
	i++;
	if (i >= 5 )
	{
		i=0;
		HAL_GPIO_WritePin(GPIOB, 0xff, 0);
		HAL_Delay(100);
	}

   //--------------org----------------------
	/*
	for (int i=0; i < 4; i++)
	{
		HAL_GPIO_WritePin(GPIOB, 0x10 << i | 0x08 >> i , 1);
//		HAL_GPIO_WritePin(GPIOB, 0x10 << i, 1);
//		HAL_GPIO_WritePin(GPIOB, 0x08 >> i, 1);
		HAL_Delay(200);
	}
	HAL_GPIO_WritePin(GPIOB, 0xff, 0);
	HAL_Delay(200);
	*/
#endif
}
void led_flower_off(void)
{
//	static int i=0;

#if 0
	if (TIM11_1ms_counter >= 100)
	{
		TIM11_1ms_counter=0;

		if (i==0)
		{
			HAL_GPIO_WritePin(GPIOB, 0xff, 1);
		}
		else
		{
			HAL_GPIO_WritePin(GPIOB, 0x01 << (i-1) | 0x80 >> (i-1), 0);
		}
		if (++i >= 4)
		{
			i=0;
		}
	}
#endif

#if 0
	if (i < 4)
	{
		if (i==0)
		{
			HAL_GPIO_WritePin(GPIOB, 0xff, 1);
			HAL_Delay(100);
			HAL_GPIO_WritePin(GPIOB, 0x01 << i |0x80 >> i, 0);
			HAL_Delay(100);
		}
		else
		{
			HAL_GPIO_WritePin(GPIOB, 0x01 << i |0x80 >> i, 0);
			HAL_Delay(100);
		}
	}
	i++;
	if (i >=4 )
	{
		i=0;
	}
#endif
}

// 7 6 5 4 3 2 1 <- 0
// 200ms주기로 동작(기존에 on led는 off로 처리)
//void led_left_on(void)
//{
//	static int i=0;
//
//	if (TIM11_1ms_counter >= 100)
//	{
//		TIM11_1ms_counter=0;
//		 if (i < 8)
//		 {
//			HAL_GPIO_WritePin(GPIOB, 0xff, 0);
//			HAL_GPIO_WritePin(GPIOB, 0x01 << i, 1);
//		 }
//		if (++i >= 8)
//		{
//			HAL_GPIO_WritePin(GPIOB, 0xff, 0);
//			i=0;
//		}
//	}
///*
//	for(int i=0; i < 8; i++)
//	{
//		HAL_GPIO_WritePin(GPIOB, 0xff, 0);
//		HAL_GPIO_WritePin(GPIOB, 0x01 << i, 1);
//		HAL_Delay(200);
//	}
//	HAL_GPIO_WritePin(GPIOB, 0xff, 0);
//	HAL_Delay(200);
//*/
//}
//
//// bit shift연산자를 이용해서 3번bit를 reset
//// 7 -> 6 5 4 3 2 1 --> 0
//// 200ms주기로 동작(기존에 on led는 on유지로 처리)
//void led_right_on(void)
//{
//	static int i=0;
//
//	if (TIM11_1ms_counter >= 100)
//	{
//		 TIM11_1ms_counter=0;
//		 if (i < 8)
//		 {
//			HAL_GPIO_WritePin(GPIOB, 0xff, 0);
//			HAL_GPIO_WritePin(GPIOB, 0x80 >> i, 1);
//		 }
//		if (++i >= 8)
//		{
//			HAL_GPIO_WritePin(GPIOB, 0xff, 0);
//			i=0;
//		}
//	}
//
////	for(int i=0; i < 8; i++)
////	{
////		HAL_GPIO_WritePin(GPIOB, 0x80 >> i, 1);
////		HAL_Delay(200);
////	}
////	HAL_GPIO_WritePin(GPIOB, 0xff, 0);
////	HAL_Delay(200);
//}
//// 7 -> 6 5 4 3 2 1 --> 0
//// 200ms주기로 동작(기존에 on led는 on로 처리)
//void led_right_keepon(void)
//{
//	static int i=0;
//
//
//	if(TIM11_1ms_counter >= 100)
//	{
//		TIM11_1ms_counter = 0;
//		if(i<8)
//		{
//			HAL_GPIO_WritePin(GPIOB, 0x80 >> i, 1);
//		}
//		if(++i>=8)
//		{
//			i=0;
//			HAL_GPIO_WritePin(GPIOB, 0xff, 0);
//		}
//	}
//
////	for(int i=0; i < 8; i++)
////	{
////		HAL_GPIO_WritePin(GPIOB, 0x80 >> i, 1);
////		HAL_Delay(200);
////	}
////	HAL_GPIO_WritePin(GPIOB, 0xff, 0);
////	HAL_Delay(200);
//}
//
//// 7 6 5 4 3 2 1 <- 0
//// 200ms주기로 동작(기존에 on led는 on으로 유지)
//void led_left_keepon(void)
//{
//	static int i =0;
//
//
//	if(TIM11_1ms_counter >= 100)
//		{
//			TIM11_1ms_counter = 0;
//			if(i<8)
//			{
//				HAL_GPIO_WritePin(GPIOB, 0x01 << i, 1);
//			}
//			if(++i>=8)
//			{
//				i=0;
//				HAL_GPIO_WritePin(GPIOB, 0xff, 0);
//			}
//		}
//
////	for(int i=0; i < 8; i++)
////	{
////		HAL_GPIO_WritePin(GPIOB, 0x01 << i, 1);
////		HAL_Delay(200);
////	}
////	HAL_GPIO_WritePin(GPIOB, 0xff, 0);
////	HAL_Delay(200);
//}
//
//
//
//
//// bit shift연산자를 이용해서 3번bit를 set
//void on_led(int led_number)
//{
//	unsigned char led=0;
//
//	led |= 1 << led_number;
//	HAL_GPIO_WritePin(GPIOB, 1 << led_number, 1);
//}
//// bit shift연산자를 이용해서 3번bit를 reset
//void off_led(int led_number)
//{
//	unsigned char led=0;
//
//	led &= ~(1 << led_number);
//	HAL_GPIO_WritePin(GPIOB, 1 << led_number, 0);
//}
//
//
//void led_all_on (void)
//{
//	HAL_GPIO_WritePin(GPIOB, 0xff , 1);
//}
//
//void led_all_off (void)
//{
//	HAL_GPIO_WritePin(GPIOB, 0xff , 0);
//}
