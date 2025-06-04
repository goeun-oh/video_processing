/*
 * i2c_lcd.c
 *
 *  Created on: 2019. 9. 4.
 *      Author: k
 */
#include "main.h"
#include "ds1302.h"
#include "stm32f4xx_hal.h"
#include <string.h>
#include <stdio.h>
#include "i2c_lcd.h"
#include "button.h"
#include "ds1302.h"
#include "buzzer.h"
#include "stm32f4xx_it.h"

#define GPIOA_START_ADDR 0x40020000
t_ds1302 ds_time;
extern TIM_HandleTypeDef htim5;
extern I2C_HandleTypeDef hi2c1;
extern UART_HandleTypeDef huart2;
extern SPI_HandleTypeDef hspi3;
extern uint8_t rx_data;  // uart rx byte

void i2c_lcd_main(void);
void i2c_lcd_init(void);
void lcd_string(uint8_t *str);
void cctv_mode(void);
extern int get_button(GPIO_TypeDef *GPIO, uint16_t GPIO_Pin, int button_number);
extern void ds1302_main();

extern volatile int TIM11_1ms_ds1302;
extern volatile int TIM11_1ms_counter;
extern void ds1302_read_time(void);
extern void ds1302_read_data(void);
extern void ds1302_init(void);
extern void ds1302_gpio_init(void);
extern void set_buzzer(int frequency);
extern void siren(int repeat);
void HAL_GPIO_EXTI_Callback(uint16_t GPIO_Pin);
extern void EXTI15_10_IRQHandler(void);
extern void HAL_UART_RxCpltCallback(UART_HandleTypeDef *huart);
extern volatile uint8_t motion_detected_flag;
extern volatile uint8_t motion_detected_flag1;
extern void ds1302_write(uint8_t addr, uint8_t data);
extern void ds1302_tx(uint8_t value);
extern void ds1302_clock(void);
extern void ds1302_DataLine_Input(void);
extern void ds1302_DataLine_Output(void);
extern void ds1302_rx(unsigned char *data);
extern unsigned char ds1302_read(uint8_t addr);
extern void ds1302_read_time(void);
extern void ds1302_read_data(void);
extern void HAL_SPI_RxCpltCallback(SPI_HandleTypeDef *hspi);
extern HAL_StatusTypeDef flash_write(uint32_t *data32, int size);
extern HAL_StatusTypeDef flash_erase();
extern void send_string_via_uart(char* str);
extern void send_time(void);
extern void send_message(char* message);
extern void receive_spi_data(void);
extern void SPI3_IRQHandler(void);
extern void flash_main();

#define BUFFER_SIZE		256
#define I2C_LCD_ADDRESS (0x27 << 1) //0x27을 write 하기위한 코드
unsigned char lcd_test[4] = {'7','0', 0};

uint8_t spi_rx_buffer[BUFFER_SIZE];

void HAL_GPIO_EXTI_Callback(uint16_t GPIO_Pin)
{
	if (GPIO_Pin == GPIO_PIN_15) {

		printf("Motion Detected!\n");
		//start_spi_transfer();
	}
}

void cctv_mode(void)
{
	static int lcd_state = 0;
	static uint8_t value = 0;

	char time_buffer[50];
	char lcd_buff[20];
	ds_time.year = 25;
	ds_time.month = 3;
	ds_time.date = 31;
	ds_time.dayofweek = 3;
	ds_time.hours = 10;
	ds_time.minutes = 16;
	ds_time.seconds = 0;

	//ds1302_init();
	ds1302_gpio_init();

	if(get_button(GPIOC, GPIO_PIN_5, BUTTON0) == BUTTON_PRESS)

	{
		lcd_state = !lcd_state;
		HAL_Delay(200);
	}

		switch(lcd_state)
		{
			//ds1302_init(); // ds1302에 ds_time의 값을 write 완료
		if (TIM11_1ms_ds1302 >= 1000)
			{
			case 0:
				i2c_lcd_init();
				TIM11_1ms_ds1302=0;
				ds1302_read_time();
				ds1302_read_data();
				send_message("CCTV ON\n");
				sprintf(time_buffer,"Time: %4d-%2d-%2d %02d:%02d:%02d\n",
						ds_time.year + 2000,
						ds_time.month,
						ds_time.date,
						ds_time.hours,
						ds_time.minutes,
						ds_time.seconds);
				send_string_via_uart(time_buffer);

				move_cursor(0,0);
				lcd_string("CCTV ON");
				sprintf(lcd_buff,"%2d:%2d:%2d       ",
								ds_time.hours,
								ds_time.minutes,
								ds_time.seconds);
				move_cursor(1,0);
				lcd_string(lcd_buff);

				break;
			case 1:

				i2c_lcd_init();
				TIM11_1ms_ds1302=0;
				ds1302_read_time();
				ds1302_read_data();

				if (motion_detected_flag == 0 || motion_detected_flag1 == 0) {
					move_cursor(0,0);
					lcd_string("Detected Mode");
					sprintf(lcd_buff,"%2d:%2d:%2d       ",
								ds_time.hours,
								ds_time.minutes,
								ds_time.seconds);
				move_cursor(1,0);
				lcd_string(lcd_buff);
				send_message("Detected Mode\n");
				sprintf(time_buffer,"Time: %4d-%2d-%2d %02d:%02d:%02d\n",
						ds_time.year + 2000,
						ds_time.month,
						ds_time.date,
						ds_time.hours,
						ds_time.minutes,
						ds_time.seconds);
				send_string_via_uart(time_buffer);
				}
				if (motion_detected_flag == 1 || motion_detected_flag1 == 1) {
					i2c_lcd_init();
					HAL_GPIO_WritePin(GPIOA,GPIO_PIN_5,1);
					HAL_Delay(100);
					HAL_GPIO_WritePin(GPIOA,GPIO_PIN_5,0);
					HAL_Delay(100);
					move_cursor(0,0);
					lcd_string("Motion Detected");
					siren(3);

					send_message("Motion Detected\n");
					sprintf(time_buffer,"Time: %4d-%2d-%2d %02d:%02d:%02d\n",
							ds_time.year + 2000,
							ds_time.month,
							ds_time.date,
							ds_time.hours,
							ds_time.minutes,
							ds_time.seconds);
					send_string_via_uart(time_buffer);

					if(flash_write((uint32_t *)&time_buffer, sizeof(time_buffer))== HAL_OK)
					{
						send_message("Time Saved to Flash\n");
					}
					else
					{
						send_message("Time Write failed\n");
					}


					motion_detected_flag = 0;
					motion_detected_flag1 = 0;
				}

				break;
			}
		}
		HAL_Delay(500);
}


void i2c_lcd_main(void)
{
//	while(1)
//	{
//		while(HAL_I2C_Master_Transmit(&hi2c1, I2C_LCD_ADDRESS,
//				lcd_test, 2, 100)!=HAL_OK)
//		{
//			// HAL_Delay(1);
//		}
//		HAL_Delay(1000);
//	}
#if 0
	uint8_t value=0;
	i2c_lcd_init();


	while(1)
	{
		move_cursor(0,0);
		lcd_string("Hello World!!!");
		move_cursor(1,0);
		lcd_data(value + '0');
		value++;
		if(value>9)value=0;
		HAL_Delay(500);
	}
#endif
}

void lcd_command(uint8_t command)
{

	uint8_t high_nibble, low_nibble;
	uint8_t i2c_buffer[4];
	high_nibble = command & 0xf0;
	low_nibble = (command<<4) & 0xf0;
	i2c_buffer[0] = high_nibble | 0x04 | 0x08; //en=1, rs=0, rw=0, backlight=1
	i2c_buffer[1] = high_nibble | 0x00 | 0x08; //en=0, rs=0, rw=0, backlight=1
	i2c_buffer[2] = low_nibble  | 0x04 | 0x08; //en=1, rs=0, rw=0, backlight=1
	i2c_buffer[3] = low_nibble  | 0x00 | 0x08; //en=0, rs=0, rw=0, backlight=1
	while(HAL_I2C_Master_Transmit(&hi2c1, I2C_LCD_ADDRESS,
			i2c_buffer, 4, 100)!=HAL_OK){
		//HAL_Delay(1);
	}
	return;
}
void lcd_data(uint8_t data)
{

	uint8_t high_nibble, low_nibble;
	uint8_t i2c_buffer[4];
	high_nibble = data & 0xf0;
	low_nibble = (data<<4) & 0xf0;
	i2c_buffer[0] = high_nibble | 0x05 | 0x08; //en=1, rs=1, rw=0, backlight=1
	i2c_buffer[1] = high_nibble | 0x01 | 0x08; //en=0, rs=1, rw=0, backlight=1
	i2c_buffer[2] = low_nibble  | 0x05 | 0x08; //en=1, rs=1, rw=0, backlight=1
	i2c_buffer[3] = low_nibble  | 0x01 | 0x08; //en=0, rs=1, rw=0, backlight=1
	while(HAL_I2C_Master_Transmit(&hi2c1, I2C_LCD_ADDRESS,
			i2c_buffer, 4, 100)!=HAL_OK)
	{
		//HAL_Delay(1);
	}
	return;
}
void i2c_lcd_init(void)
{

	lcd_command(0x33);
	lcd_command(0x32);
	lcd_command(0x28);	//Function Set 4-bit mode
	lcd_command(DISPLAY_ON);
	lcd_command(0x06);	//Entry mode set
	lcd_command(CLEAR_DISPLAY);
	HAL_Delay(2);
}
void lcd_string(uint8_t *str)
{
	while(*str)lcd_data(*str++);
}
void move_cursor(uint8_t row, uint8_t column)
{
	lcd_command(0x80 | row<<6 | column);
	return;
}











