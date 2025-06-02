#if 0
#include "ds1302.h"

t_ds1302 ds_time;

unsigned char bcd2dec(unsigned char byte);
unsigned char dec2bcd(unsigned char byte);
void ds1302_gpio_init(void);
void ds1302_init(void);
void ds1302_write(uint8_t addr, uint8_t data);
void ds1302_tx(uint8_t value);
void ds1302_clock(void);
void ds1302_DataLine_Input(void);
void ds1302_DataLine_Output(void);
void ds1302_rx(unsigned char *data);
unsigned char ds1302_read(uint8_t addr);
void ds1302_read_time(void);
void ds1302_read_data(void);

void ds1302_main();
void stopwatch_run(void);
void stopwatch_stop(void);

int sec_value = 0;
int min_value = 0;
int hour_value = 0;

extern void move_cursor(uint8_t row, uint8_t column);
extern void lcd_string(uint8_t *str);
extern volatile int TIM11_1ms_ds1302;
extern volatile int TIM11_1ms_counter;
extern volatile int TIM11_1ms_stopwatch;

#define GPIOA_START_ADDR 0x40020000
// uint8_t Year
// 예) 24년의 Year에 저장된 data format
//  7654 3210
//  0010 0100
//    2   4
//  ===> 24
unsigned char bcd2dec(unsigned char byte)
{
	unsigned char high, low;

	low = byte & 0x0f;
	high = (byte >> 4) * 10;

	return (high+low);
}

//          10진수를       bcd로 변환
// 예) 24 ( 00011000) --> 0010 0100
//STM32의 RTC에서 날짜와 시각정보를 읽어 오는 함수를 작성
unsigned char dec2bcd(unsigned char byte)
{
	unsigned char high, low;


	high = (byte / 10) << 4;
    low  = byte % 10;

	return (high+low);
}

void ds1302_gpio_init(void)
{
	//*(unsigned int *)(GPIOA_START_ADDR + 0x14) &= ~(1 << 12);
	HAL_GPIO_WritePin(CLK_DS1302_GPIO_Port, CLK_DS1302_Pin, 0);
	//*(unsigned int *)(GPIOA_START_ADDR + 0x14) &= ~(1 << 11);
	HAL_GPIO_WritePin(IO_DS1302_GPIO_Port, IO_DS1302_Pin, 0);
	//*(unsigned int *)(GPIOA_START_ADDR + 0x14) &= ~(1 << 10);
	HAL_GPIO_WritePin(CE_DS1302_GPIO_Port, CE_DS1302_Pin, 0);
}

void ds1302_init(void)
{
	ds1302_write(ADDR_SECONDS,ds_time.seconds);
	ds1302_write(ADDR_MINUTES,ds_time.minutes);
	ds1302_write(ADDR_HOURS,ds_time.hours);
	ds1302_write(ADDR_DATE,ds_time.date);
	ds1302_write(ADDR_MONTH,ds_time.month);
	ds1302_write(ADDR_DAYOFWEEK,ds_time.dayofweek);
	ds1302_write(ADDR_YEAR,ds_time.year);
}

void ds1302_write(uint8_t addr, uint8_t data)
{
	/*
	 * 1. CE low -> high
	 * 2. addr 전송
	 * 3. data 전송
	 * 4. CE high -> low
	 */

	// 1. CE low --> high
	*(unsigned int *)(GPIOA_START_ADDR + 0x14) |= 1 << 10;
	//HAL_GPIO_WritePin(CE_DS1302_GPIO_Port, CE_DS1302_Pin, 1);

	// 2. addr 전송
	ds1302_tx(addr);

	// 3. data 전송
	ds1302_tx(dec2bcd(data));

	// 4. CE high --> low
	*(unsigned int *)(GPIOA_START_ADDR + 0x14) &= ~(1 << 10);
	//HAL_GPIO_WritePin(CE_DS1302_GPIO_Port, CE_DS1302_Pin, 0);

}

void ds1302_tx(uint8_t value)
{
	ds1302_DataLine_Output();
	// ADDR 0x80 sec write
	/* 80h M       L
	*      1000 0000
	*      0000 0001 &
	*   ===============
	*      0000 0000
	*
	*      1000 0000
	*      1000 0000 &
	*      ===========
	*      1000 0000
	*/

	for (int i = 0; i < 8; i++)
	{
		if (value & (1<<i)) // bit가 1인 경우
		{
			 *(unsigned int *)(GPIOA_START_ADDR + 0x14) |= 1 << 11;
			//HAL_GPIO_WritePin(IO_DS1302_GPIO_Port, IO_DS1302_Pin, 1);
		}
		else // bit가 0인 경우
		{
			*(unsigned int *)(GPIOA_START_ADDR + 0x14) &= ~(1 << 11);
			//HAL_GPIO_WritePin(IO_DS1302_GPIO_Port, IO_DS1302_Pin, 0);
		}
		ds1302_clock();
	}


}

void ds1302_clock(void)
{
	 *(unsigned int *)(GPIOA_START_ADDR + 0x14) |= 1 << 12;
	//HAL_GPIO_WritePin(CLK_DS1302_GPIO_Port, CLK_DS1302_Pin, 1);
	 *(unsigned int *)(GPIOA_START_ADDR + 0x14) &= ~(1 << 12);
	//HAL_GPIO_WritePin(CLK_DS1302_GPIO_Port, CLK_DS1302_Pin, 0);
}

void ds1302_DataLine_Input(void)
{
    GPIO_InitTypeDef GPIO_InitStruct = {0};

    /*Configure GPIO pin : PH0 */
  GPIO_InitStruct.Pin = IO_DS1302_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_INPUT;            //Change Output to Input
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  HAL_GPIO_Init(IO_DS1302_GPIO_Port, &GPIO_InitStruct);

    return;
}


void ds1302_DataLine_Output(void)
{
    GPIO_InitTypeDef GPIO_InitStruct = {0};

    /*Configure GPIO pin : PH0 */
  GPIO_InitStruct.Pin = IO_DS1302_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;            //Change Input to Output
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_HIGH;	// LOW: 2M, HIGH: 25 ~ 100 MHz
  HAL_GPIO_Init(IO_DS1302_GPIO_Port, &GPIO_InitStruct);

    return;
}

void ds1302_rx(unsigned char *data)
{
	unsigned char temp = 0;

	ds1302_DataLine_Input();  // 입력모드로 전환

	// DS1302로 부터 넘어오는 data를 LSB부터 받아 들인다.
	for (int i = 0; i < 8; i++)
	{
		// 1bit읽어들인다.
		if (HAL_GPIO_ReadPin(IO_DS1302_GPIO_Port, IO_DS1302_Pin))
		{
			temp |= 1 << i;
		}
		if (i !=7)
		ds1302_clock();
	}
	*data = temp;
}
unsigned char ds1302_read(uint8_t addr)
{
	unsigned char data8bits = 0;
	// 1. CE high
	*(unsigned int *)(GPIOA_START_ADDR + 0x14) |= 1 << 10;
	//HAL_GPIO_WritePin(CE_DS1302_GPIO_Port, CE_DS1302_Pin, 1);
	// 2. addr 전송
	ds1302_tx(addr + 1);
	// 3. data 읽어들인다.
	ds1302_rx(&data8bits);
	// 4. CE low
	*(unsigned int *)(GPIOA_START_ADDR + 0x14) &= ~(1 << 10);
	//HAL_GPIO_WritePin(CE_DS1302_GPIO_Port, CE_DS1302_Pin, 0);
	// 5. bcd to dec
	return bcd2dec(data8bits);
}

void ds1302_read_time(void)
{
	ds_time.seconds = ds1302_read(ADDR_SECONDS);
	ds_time.minutes = ds1302_read(ADDR_MINUTES);
	ds_time.hours = ds1302_read(ADDR_HOURS);
}

void ds1302_read_data(void)
{
	ds_time.date = ds1302_read(ADDR_DATE);
	ds_time.month = ds1302_read(ADDR_MONTH);
	ds_time.dayofweek = ds1302_read(ADDR_DAYOFWEEK);
	ds_time.year = ds1302_read(ADDR_YEAR);
}


void ds1302_main()
{

	static int demo_led = 0;
	char lcd_buff[20];

	ds_time.year = 25;
	ds_time.month = 3;
	ds_time.date = 25;
	ds_time.dayofweek = 3;
	ds_time.hours = 13;
	ds_time.minutes = 3;
	ds_time.seconds = 0;

	ds1302_gpio_init();
	ds1302_init(); // ds1302에 ds_time의 값을 write 완료

	if (TIM11_1ms_ds1302 >= 1000)
	{
		TIM11_1ms_ds1302=0;
		// 1. ds1302의 시간 값을 읽고
		ds1302_read_time();
		// 2. ds1302의 날짜 값을 읽고
		ds1302_read_data();
		// 3. 시간과 날짜를 printf
		printf("***%4d-%2d-%2d %2d:%2d:%2d\n",
					ds_time.year+2000,
					ds_time.month,
					ds_time.date,
					ds_time.hours,
					ds_time.minutes,
					ds_time.seconds);
		sprintf(lcd_buff,"%4d-%2d-%2d       ",
						ds_time.year+2000,
						ds_time.month,
						ds_time.date);
		move_cursor(0,0);
		lcd_string(lcd_buff);
		sprintf(lcd_buff,"%2d:%2d:%2d       ",
						ds_time.hours,
						ds_time.minutes,
						ds_time.seconds);
		move_cursor(1,0);
		lcd_string(lcd_buff);
		// 4. 1초 delay
		// HAL_Delay(1000);
	}
	if (TIM11_1ms_counter >=500)
	{
		TIM11_1ms_counter=0;
		demo_led = !demo_led;
		if (demo_led)
		{
			printf("GPIOA -> ODR: %0x\n", &GPIOA -> ODR);
			*(unsigned int *)(GPIOA_START_ADDR + 0x14) |= 1 << 5;
//				GPIOA -> ODR |= GPIO_PIN_5;
		}
		else
		{
			// 1)                         100000 (1 << 5)
			// 2)                         011111 ~(1 << 5)
			*(unsigned int *)(GPIOA_START_ADDR + 0x14) &= ~(1 << 5);
//				GPIOA -> ODR &= ~GPIO_PIN_5;
		}
	}

}

void stopwatch_run(void)
{
	char lcd_buff[20];

	if(TIM11_1ms_stopwatch >=1000)
	{
		TIM11_1ms_stopwatch = 0;
		if(sec_value >= 59)
		{
			sec_value = 0;
			if(min_value >= 59)
			{
				min_value = 0;
				hour_value = hour_value +1;
			}
			else
			{
				min_value = min_value +1;
			}
		}
		else
		{
			sec_value = sec_value +1;
		}
	}

	move_cursor(0, 0);
	lcd_string("STOPWATCH");

	move_cursor(1, 0);
	sprintf(lcd_buff,"%d : %d : %d       ",hour_value,min_value,sec_value);
	lcd_string(lcd_buff);

}

void stopwatch_stop(void)
{
	char lcd_buff[20];
	sec_value = sec_value;
	min_value = min_value;
	hour_value = hour_value;

	move_cursor(0, 0);
	lcd_string("STOPWATCH ");

	move_cursor(1, 0);
	sprintf(lcd_buff,"%d : %d : %d       ",hour_value,min_value,sec_value);
	lcd_string(lcd_buff);
}
#endif

#if 1
#include "ds1302.h"

t_ds1302 ds_time;

unsigned char bcd2dec(unsigned char byte);
unsigned char dec2bcd(unsigned char byte);
void ds1302_gpio_init(void);
void ds1302_init(void);
void ds1302_write(uint8_t addr, uint8_t data);
void ds1302_tx(uint8_t value);
void ds1302_clock(void);
void ds1302_DataLine_Input(void);
void ds1302_DataLine_Output(void);
void ds1302_rx(unsigned char *data);
unsigned char ds1302_read(uint8_t addr);
void ds1302_read_time(void);
void ds1302_read_data(void);
void ds1302_main();

extern volatile int TIM11_1ms_ds1302;
extern volatile int TIM11_1ms_counter;
// uint8_t Year
// 예) 24년의 Year에 저장된 data format
//  7654 3210
//  0010 0100
//    2   4
//  ===> 24
unsigned char bcd2dec(unsigned char byte)
{
	unsigned char high, low;

	low = byte & 0x0f;
	high = (byte >> 4) * 10;

	return (high+low);
}

//          10진수를       bcd로 변환
// 예) 24 ( 00011000) --> 0010 0100
//STM32의 RTC에서 날짜와 시각정보를 읽어 오는 함수를 작성
unsigned char dec2bcd(unsigned char byte)
{
	unsigned char high, low;


	high = (byte / 10) << 4;
    low  = byte % 10;

	return (high+low);
}

void ds1302_gpio_init(void)
{
	HAL_GPIO_WritePin(CLK_DS1302_GPIO_Port, CLK_DS1302_Pin, 0);
	HAL_GPIO_WritePin(IO_DS1302_GPIO_Port, IO_DS1302_Pin, 0);
	HAL_GPIO_WritePin(CE_DS1302_GPIO_Port, CE_DS1302_Pin, 0);
}

void ds1302_init(void)
{
	ds1302_write(ADDR_SECONDS,ds_time.seconds);
	ds1302_write(ADDR_MINUTES,ds_time.minutes);
	ds1302_write(ADDR_HOURS,ds_time.hours);
	ds1302_write(ADDR_DATE,ds_time.date);
	ds1302_write(ADDR_MONTH,ds_time.month);
	ds1302_write(ADDR_DAYOFWEEK,ds_time.dayofweek);
	ds1302_write(ADDR_YEAR,ds_time.year);
}

void ds1302_write(uint8_t addr, uint8_t data)
{
	/*
	 * 1. CE low -> high
	 * 2. addr 전송
	 * 3. data 전송
	 * 4. CE high -> low
	 */

	// 1. CE low --> high
	HAL_GPIO_WritePin(CE_DS1302_GPIO_Port, CE_DS1302_Pin, 1);

	// 2. addr 전송
	ds1302_tx(addr);

	// 3. data 전송
	ds1302_tx(dec2bcd(data));

	// 4. CE high --> low
	HAL_GPIO_WritePin(CE_DS1302_GPIO_Port, CE_DS1302_Pin, 0);

}

void ds1302_tx(uint8_t value)
{
	ds1302_DataLine_Output();
	// ADDR 0x80 sec write
	/* 80h M       L
	*      1000 0000
	*      0000 0001 &
	*   ===============
	*      0000 0000
	*
	*      1000 0000
	*      1000 0000 &
	*      ===========
	*      1000 0000
	*/

	for (int i = 0; i < 8; i++)
	{
		if (value & (1<<i)) // bit가 1인 경우
		{
			HAL_GPIO_WritePin(IO_DS1302_GPIO_Port, IO_DS1302_Pin, 1);
		}
		else // bit가 0인 경우
		{
			HAL_GPIO_WritePin(IO_DS1302_GPIO_Port, IO_DS1302_Pin, 0);
		}
		ds1302_clock();
	}


}

void ds1302_clock(void)
{
	HAL_GPIO_WritePin(CLK_DS1302_GPIO_Port, CLK_DS1302_Pin, 1);
	HAL_GPIO_WritePin(CLK_DS1302_GPIO_Port, CLK_DS1302_Pin, 0);
}

void ds1302_DataLine_Input(void)
{
    GPIO_InitTypeDef GPIO_InitStruct = {0};

    /*Configure GPIO pin : PH0 */
  GPIO_InitStruct.Pin = IO_DS1302_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_INPUT;            //Change Output to Input
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  HAL_GPIO_Init(IO_DS1302_GPIO_Port, &GPIO_InitStruct);

    return;
}


void ds1302_DataLine_Output(void)
{
    GPIO_InitTypeDef GPIO_InitStruct = {0};

    /*Configure GPIO pin : PH0 */
  GPIO_InitStruct.Pin = IO_DS1302_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;            //Change Input to Output
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_HIGH;	// LOW: 2M, HIGH: 25 ~ 100 MHz
  HAL_GPIO_Init(IO_DS1302_GPIO_Port, &GPIO_InitStruct);

    return;
}

void ds1302_rx(unsigned char *data)
{
	unsigned char temp = 0;

	ds1302_DataLine_Input();  // 입력모드로 전환

	// DS1302로 부터 넘어오는 data를 LSB부터 받아 들인다.
	for (int i = 0; i < 8; i++)
	{
		// 1bit읽어들인다.
		if (HAL_GPIO_ReadPin(IO_DS1302_GPIO_Port, IO_DS1302_Pin))
		{
			temp |= 1 << i;
		}
		if (i !=7)
		ds1302_clock();
	}
	*data = temp;
}
unsigned char ds1302_read(uint8_t addr)
{
	unsigned char data8bits = 0;

	HAL_GPIO_WritePin(CE_DS1302_GPIO_Port, CE_DS1302_Pin, 1);
	ds1302_tx(addr + 1);
	ds1302_rx(&data8bits);
	HAL_GPIO_WritePin(CE_DS1302_GPIO_Port, CE_DS1302_Pin, 0);
	return bcd2dec(data8bits);
}

void ds1302_read_time(void)
{
	ds_time.seconds = ds1302_read(ADDR_SECONDS);
	ds_time.minutes = ds1302_read(ADDR_MINUTES);
	ds_time.hours = ds1302_read(ADDR_HOURS);
}

void ds1302_read_data(void)
{
	ds_time.date = ds1302_read(ADDR_DATE);
	ds_time.month = ds1302_read(ADDR_MONTH);
	ds_time.dayofweek = ds1302_read(ADDR_DAYOFWEEK);
	ds_time.year = ds1302_read(ADDR_YEAR);
}

#define GPIOA_START_ADDR 0x40020000
void ds1302_main()
{
	static int demo_led = 0;
	char lcd_buff[20];
	ds_time.year = 25;
	ds_time.month = 3;
	ds_time.date = 25;
	ds_time.dayofweek = 3;
	ds_time.hours = 15;
	ds_time.minutes = 36;
	ds_time.seconds = 0;

	ds1302_gpio_init();
	ds1302_init(); // ds1302에 ds_time의 값을 write 완료

	while(1)
	{
		if (TIM11_1ms_ds1302 >= 1000)
		{
			TIM11_1ms_ds1302=0;
			// 1. ds1302의 시간 값을 읽고
			ds1302_read_time();
			// 2. ds1302의 날짜 값을 읽고
			ds1302_read_data();
			// 3. 시간과 날짜를 printf
			printf("***%4d-%2d-%2d %2d:%2d:%2d\n",
						ds_time.year+2000,
						ds_time.month,
						ds_time.date,
						ds_time.hours,
						ds_time.minutes,
						ds_time.seconds);
			sprintf(lcd_buff,"%4d-%2d-%2d       ",
							ds_time.year+2000,
							ds_time.month,
							ds_time.date);
//			move_cursor(0,0);
//			lcd_string(lcd_buff);
			sprintf(lcd_buff,"%2d:%2d:%2d       ",
							ds_time.hours,
							ds_time.minutes,
							ds_time.seconds);
			move_cursor(1,0);
			lcd_string(lcd_buff);
			// 4. 1초 delay
			// HAL_Delay(1000);
		}
		if (TIM11_1ms_counter >=500)
		{
			TIM11_1ms_counter=0;
			demo_led = !demo_led;
			if (demo_led)
			{
				printf("GPIOA -> ODR: %0x\n", &GPIOA -> ODR);
				*(unsigned int *)(GPIOA_START_ADDR + 0x14) |= 1 << 5;
//				GPIOA -> ODR |= GPIO_PIN_5;
			}
			else
			{
				// 1)                         100000 (1 << 5)
				// 2)                         011111 ~(1 << 5)
				*(unsigned int *)(GPIOA_START_ADDR + 0x14) &= ~(1 << 5);
//				GPIOA -> ODR &= ~GPIO_PIN_5;
			}
		}
	}
}

//TimeData get_time_from_ds1302() {
//	TimeData time;
//	ds_time.year = ds1302_read_time(ds1302_year);
//	ds_time.month = ds1302_read_time(ds1302_month);
//	ds_time.date = ds1302_read_time(ds1302_date);
//	ds_time.hours = ds1302_read_time(ds1302_hours);
//	ds_time.minutes = ds1302_read_time(ds1302_minutes);
//	ds_time.seconds = ds1302_read_time(ds1302_seconds);
//	return ds_time;
//}
#endif
