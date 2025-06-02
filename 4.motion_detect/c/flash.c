#if 1
#include "main.h"

#include <stdio.h>
#include <string.h>

/**************************************************
     Flash module organization(STM32F411)
                               512KBytes

Name        Block base address              size
====      ==================   =======
Sector 0    0x8000000-0x8003FFF           16K bytes
Sector 1    0x8004000-0x8007FFF           16K bytes
Sector 2    0x8008000-0x800BFFF           16K bytes
Sector 3    0x800C000-0x800FFFF           16K bytes
Sector 4    0x8010000-0x801FFFF           64K bytes
Sector 5    0x8020000-0x803FFFF          128K bytes
Sector 6    0x8040000-0x805FFFF          128K bytes
Sector 7    0x8060000-0x807FFFF          128K bytes

******************************************************/

// 0x8060000-0x807FFFF 의 빈공간에 사용자 데이터를 flash programming
// 하도록 설정 한다.
#define ADDR_FLASH_SECTOR7      ((uint32_t) 0x8060000)
#define FLASH_USER_START_ADDR   ((uint32_t) 0x8060000)
#define USER_DATA_ADDRESS        0x8060000
#define USER_DATA_ADDRESS4		 0x8060004
#define FLASH_USER_END_ADDR     ((uint32_t) 0x807FFFF)
#define FLASH_INIT_STATUS       0xFFFFFFFF        // flash 초기 상태
#define FLASH_NOT_INIT_STATUS   0xAAAAAAAA        // flash 초기 상태가 아니다
#define DATA_32                 ((uint32_t) 0x00000001)

HAL_StatusTypeDef flash_write(uint32_t *data32, int size);
HAL_StatusTypeDef flash_read(uint32_t *data32, int size);
HAL_StatusTypeDef flash_erase();
void flash_main();
void flash_ds1302();
void flash_score_management(void);
void save_data_to_flash(t_ds1302 *ds_time, uint8_t *image_data, uint32_t image_size);
uint32_t flash_read_value=0;
extern void SPI3_IRQHandler(void);

typedef struct student
{
	uint32_t magic;
    int num;        // hakbun
    char name[20];  // name
    double grade;   // hakjum
} t_student;

t_student student;

typedef struct st
{
	int num;        // hakbun
    char name[20];  // name
    double grade;   // hakjum
} t_st;

t_st st[] =
{
		{100, "park", 4.0},
		{200, "kim", 3.0},
		{300, "lee", 4.2}
};


extern t_ds1302 ds_time;
extern void ds1302_init(void);

void flash_score_management(void)
{

	flash_read_value = *(__IO uint32_t *) USER_DATA_ADDRESS4;
	uint32_t magic = 0xAAAAAAAA;
	if (flash_read_value == FLASH_INIT_STATUS)  // 초기에 아무런 데이터도 존재 하지 않을 경우
		{
			flash_erase();

			flash_write((uint32_t*)&magic,sizeof(magic));

			for(int i = 0; i < 3; i++)
			{
				printf("num: %d\n",st[i].num);
				printf("name: %d\n",st[i].name);
				printf("grade: %d\n",st[i].grade);
			}
			flash_write((uint32_t *) &st, sizeof(st));
		}
		else   // 1번 이상 flash memory에 데이터를 write 한 경우
		{
			flash_read((uint32_t *) &st, sizeof(st));

			printf("      score       \n");
			printf("     ======       \n");
			printf("num  name   grade\n");
			printf("==== ====   ====\n");
			for(int i = 0; i < 3; i++)
			{
			//printf("%08x %s     %lf\n", st[i].num, st[i].name, st[i].grade);
			}
			printf("==================\n");
		}
}
void flash_ds1302()
{

	t_ds1302 *read_ds1302;

	flash_read_value = *(__IO uint32_t *) USER_DATA_ADDRESS;

	if (flash_read_value == FLASH_INIT_STATUS)  // 초기에 아무런 데이터도 존재 하지 않을 경우
	{
		//ds_time.magic=0xAAAAAAAA;
		ds_time.year = 24;
		ds_time.month = 11;
		ds_time.date = 29;
		ds_time.dayofweek = 6;
		ds_time.hours = 11;
		ds_time.minutes = 54;
		ds_time.seconds = 0;
		//ds_time.dummy[0] = 0;
		//ds_time.dummy[1] = 0;
		//ds_time.dummy[2] = 0;

		ds1302_init();

		flash_erase();
		flash_write((uint32_t *) &ds_time, sizeof(ds_time));
	}
	else   // 1번 이상 flash memory에 데이터를 write 한 경우
	{
		flash_read((uint32_t *) &ds_time, sizeof(ds_time));

		//printf("magic: %08x\n", ds_time.magic);
		printf("year: %d\n", 	ds_time.year);
		printf("month: %d\n", ds_time.month);
	}
}

void flash_main()
{

	t_student *read_student;

	flash_read_value = *(__IO uint32_t *) USER_DATA_ADDRESS;

	if (flash_read_value == FLASH_INIT_STATUS)  // 초기에 아무런 데이터도 존재 하지 않을 경우
	{
		flash_erase();

		student.magic=0x55555555;
		student.num=1101815;
		strncpy((char *)&student.name,"Hong_Gil_Dong", strlen("Hong_Gil_Dong"));
		student.grade=4.0;

		printf("w magic: %08x\n", student.magic);
		printf("w num: %08x\n", 	student.num);
		printf("w name: %s\n", student.name);
		//printf("w grade: %lf\n", student.grade);
		flash_write((uint32_t *) &student, sizeof(student));
	}
	else   // 1번 이상 flash memory에 데이터를 write 한 경우
	{
		flash_read((uint32_t *) &student, sizeof(student));

		printf("magic: %08x\n", student.magic);
		printf("num: %08x\n", 	student.num);
		printf("name: %s\n", student.name);
		//printf("r grade: %lf\n", student.grade);
	}
}


HAL_StatusTypeDef flash_write(uint32_t *data32, int size)
{
	uint32_t *mem32 = data32;	// mem32에는 0x8060000저장
	uint32_t Address = FLASH_USER_START_ADDR;

  /* Unlock to control */
	HAL_FLASH_Unlock();

	flash_erase();
  /* Writing data to flash memory */
  for (int i=0; i < size; i+=4)
  {
	  if(HAL_FLASH_Program(FLASH_TYPEPROGRAM_WORD, Address, *mem32) == HAL_OK)
	  {
		  Address += 4; 	//= Address + 4
		  mem32++;
	  }
	  else
	  {
		  uint32_t errorcode = HAL_FLASH_GetError();
		  return HAL_ERROR;
	  }
  }
  /* Lock flash control register */
  HAL_FLASH_Lock();

  return HAL_OK;
}

HAL_StatusTypeDef flash_read(uint32_t *data32, int size)
{

  uint32_t address = FLASH_USER_START_ADDR;
  uint32_t end_address = FLASH_USER_START_ADDR + size;

  while(address < end_address)
  {
    *data32 = *(uint32_t*) address;
    data32++;
    address = address + 4;
  }

  return HAL_OK;

}


HAL_StatusTypeDef flash_erase()
{
	uint32_t SectorError = 0;

	/* Unlock to control */
	HAL_FLASH_Unlock();

	/* Calculate sector index */
	uint32_t UserSector = 7;     // sector 번호
	uint32_t NbOfSectors = 1;    // sector 수

	/* Erase sectors */
	FLASH_EraseInitTypeDef EraseInitStruct;
	EraseInitStruct.TypeErase = FLASH_TYPEERASE_SECTORS;
	EraseInitStruct.VoltageRange = FLASH_VOLTAGE_RANGE_3;
	EraseInitStruct.Sector = UserSector;
	EraseInitStruct.NbSectors = NbOfSectors;

	if (HAL_FLASHEx_Erase(&EraseInitStruct, &SectorError) != HAL_OK)
	{
		uint32_t errorcode = HAL_FLASH_GetError();
		return HAL_ERROR;
	}

	/* Lock flash control register */
	HAL_FLASH_Lock();

	return HAL_OK;
}
#endif

//void save_data_to_flash(t_ds1302 *ds_time, uint8_t *image_data, uint32_t image_size) {
//
//	HAL_FLASH_Unlock();
//
//    // 1. 플래시 메모리 삭제 (기존 데이터 지우기)
//    flash_erase();
//
//    // 2. 시간 데이터 저장
//    uint32_t time_data = (time->year << 24) | (time->month << 16) | (time->day << 8) | time->hour;
//    HAL_FLASH_Program(FLASH_TYPEPROGRAM_WORD, FLASH_USER_START_ADDRESS, time_data);
//
//    uint32_t time_data2 = (time->minute << 16) | (time->second << 8);
//    HAL_FLASH_Program(FLASH_TYPEPROGRAM_WORD, FLASH_USER_START_ADDRESS + 4, time_data2);
//
//    // 3. 영상 데이터 저장 (4바이트씩 저장)
//    for (uint32_t i = 0; i < image_size; i += 4) {
//        uint32_t word = *(uint32_t *)(image_data + i);
//        HAL_FLASH_Program(FLASH_TYPEPROGRAM_WORD, FLASH_USER_START_ADDRESS + 8 + i, word);
//    }
//
//    HAL_FLASH_Lock();
//}

void save_image_to_flash(void) {
	uint8_t spi_rx_buffer[256];
	uint32_t flash_address = 0x0000;


}
