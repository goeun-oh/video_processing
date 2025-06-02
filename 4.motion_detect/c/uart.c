#include "uart.h"

#include <string.h>   // strncmp strcpy.....

#define COMMAND_NUMBER 20
#define COMMAND_LENGTH 40

void pc_command_processing(void);

volatile uint8_t rx_buffer[COMMAND_NUMBER][COMMAND_LENGTH];
volatile int rear=0;
volatile int front=0;

extern UART_HandleTypeDef huart2;
extern uint8_t rx_data;  // uart rx byte
extern void ds1302_read_time(void);

//extern int func_index=0;
extern int func_index;
extern void (*funcp[])();
// move Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_uart.c to here
// comportamaster로부터 1 char를 수신할때 마다 이곳으로 자동 진입된다.
// led_flower_on\n
// 9600bps 인경우는 HAL_UART_RxCpltCallbackt 수행후 1ms안에는 빠져나가야 한다.
void HAL_UART_RxCpltCallback(UART_HandleTypeDef *huart)
{
	volatile static int i=0;

	if (huart == &huart2)
	{
		uint8_t data;

		data = rx_data;

		if (data == '\n')
		{
			rx_buffer[rear][i++] = '\0';  // 문장의 끝을 NULL로
			i=0;
			rear++;
			if (rear >= COMMAND_NUMBER)
			{
				rear = 0;
			}
			//rear %= COMMAND_NUMBER;
			// !!!! queue full 체크하는 logic이 들어 가야 한다. !!!!!
		}
		else
		{
			rx_buffer[rear][i++] = data;  //(1) rx_buffer[rear][i] = data;
										  //(2) i++
		}
		HAL_UART_Receive_IT(&huart2, &rx_data, 1);  // uart2		                                            // 반드시 집어 넣어야 다음 INT발생
	}
}

void pc_command_processing(void)
{

	if (front != rear)  // rx_buff에 데이터 존재
	{
		 // rx_buff[front] 와 동일 &rx_buff[front][0]
		printf("rx_buffer: %s\n", rx_buffer[front]);
		if ( strncmp( (char *)rx_buffer[front], "led_all_on", strlen("led_all_on")) == 0)
		{
			func_index = 0;
		}
		else if (strncmp( ( char*)rx_buffer[front], "led_all_off", strlen("led_all_off")) == 0)
		{
			func_index = 1;
		}
		else if (strncmp( ( char*) rx_buffer[front], "led_left_on", strlen("led_left_on")) == 0)
		{
			func_index = 2;
		}
		else if (strncmp(( char*)rx_buffer[front], "led_right_on", strlen("led_right_on")) == 0)
		{
			func_index = 3;
		}
		else if (strncmp(( char*)rx_buffer[front], "led_flower_on", strlen("led_flower_on")) == 0)
		{
			func_index = 4;
		}else if (strncmp(( char*)rx_buffer[front], "led_flower_off", strlen("led_flower_off")) == 0)
		{
			func_index = 5;
		}
		else if (strncmp((  char*)rx_buffer[front], "led_left_keepon", strlen("led_left_keepon")) == 0)
		{
			func_index = 6;
		}
		else if (strncmp((  char*)rx_buffer[front], "led_right_keepon", strlen("led_right_keepon")) == 0)
		{
			func_index = 7;
		}

		front++;
		front %= COMMAND_NUMBER;
		// !!!!! queue full check 하는 기능 추가 요망 !!!!!
	}

	if (func_index != -1) // 인덱스 0~7에 해당하는 명령어를 입력받지 못 하면, 함수포인터에 들어가지 못 함.
		funcp[func_index]();
}

t_ds1302 ds_time;

void send_string_via_uart(char* str)
{
	HAL_UART_Transmit(&huart2,(uint8_t*)str, strlen(str), 1000);
}

void send_time(void)
{
	ds1302_read_time();
	char time_buffer[50];
	ds_time.year = 25;
	ds_time.month = 3;
	ds_time.date = 26;
	ds_time.dayofweek = 7;
	ds_time.hours = 16;
	ds_time.minutes = 2;
	ds_time.seconds = 0;

	sprintf(time_buffer,"Time: %4d-%2d-%2d %02d:%02d:%02d\n",ds_time.year + 2000, ds_time.month, ds_time.date, ds_time.hours, ds_time.minutes, ds_time.seconds);
	send_string_via_uart(time_buffer);
}

void send_message(char* message)
{
	send_string_via_uart(message);
}

