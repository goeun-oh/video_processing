/*
 * spi.c
 *
 *  Created on: Mar 25, 2025
 *      Author: kccistc
 */

#include "main.h"
#include "stm32f4xx_hal.h"
#include "stm32f4xx_hal_spi.h"
#include "stdio.h"
#include "string.h"



extern SPI_HandleTypeDef hspi3;
extern HAL_StatusTypeDef flash_erase();
extern HAL_StatusTypeDef flash_write(uint32_t *data32, int size);
extern void save_data_to_flash(t_ds1302 *ds_time, uint8_t *image_data, uint32_t image_size);
extern void send_message(char* message);
extern void send_string_via_uart(char* str);

#define FLASH_USER_START_ADDR 0x8060000
#define BUFFER_SIZE		256
#define SPI_TIMEOUT 1000

uint16_t received_rgb_data[76800];
uint8_t spi_rx_buffer[BUFFER_SIZE];
uint32_t flash_write_buffer[BUFFER_SIZE / 4];


void HAL_SPI_RxCpltCallback(SPI_HandleTypeDef *hspi)
{
	if (hspi->Instance == SPI3) {

		 for (int i = 0; i < BUFFER_SIZE / 4; i++) {
		            flash_write_buffer[i] = (spi_rx_buffer[i * 4] << 24) |
		                                    (spi_rx_buffer[i * 4 + 1] << 16) |
		                                    (spi_rx_buffer[i * 4 + 2] << 8) |
		                                    (spi_rx_buffer[i * 4 + 3]);
		        }
	        flash_erase();
	        flash_write(flash_write_buffer, BUFFER_SIZE);

	        printf("SPI 데이터 수신 완료 & Flash 저장 완료!\n");
	}
}



void receive_spi_data(void) {

	uint8_t received_data;
//	uint8_t received_data[256];
//	HAL_StatusTypeDef status;
//
//	status = HAL_SPI_Receive(&hspi3, received_data, sizeof(received_data), HAL_MAX_DELAY);
//	if (status == HAL_OK) {
//		status = flash_write((uint32_t*)received_data, sizeof(received_data)/4);
//		if (status != HAL_OK) {
//			printf("Flash write failed\n");
//		} else {
//			printf("Data written to Flash successfully\n");
//		}
//	} else {
//		printf("SPI receive failed\n");
//	}
}


//for(int i = 0; i < 76800; i++) {
//	HAL_SPI_Receive(&hspi3, spi_buffer, 2, HAL_MAX_DELAY);
//
//	gray_data = ((uint16_t)spi_buffer[0] << 4 | (spi_buffer[1] >> 4));
//	received_gray_data[i] = gray_data;
//
//	HAL_FLASH_Program(FLASH_TYPEPROGRAM_HALFWORD, flash_addr, gray_data);
//	flash_addr += 2;
//}
//HAL_FLASH_Lock();
#if 0
uint8_t spi_rx_buffer[8];
uint8_t spi_tx_buffer[8] = {0xA5, 0xB3, 0xC7, 0xD9, 0xE1, 0xF2, 0x00, 0xFF};

void HAL_SPI_RxCpltCallback(SPI_HandleTypeDef *hspi)
{
	if (hspi->Instance == SPI3) {
		printf("Received Data : 0x%X\n", spi_rx_buffer[0]);

	HAL_SPI_Transmit(&hspi3, spi_tx_buffer, sizeof(spi_tx_buffer), HAL_MAX_DELAY);

	HAL_SPI_Receive_IT(&hspi3, spi_rx_buffer, sizeof(spi_rx_buffer));

	}
}
#endif

#if 0
uint8_t spi_rx_buffer[];
uint32_t pixel_count = 0;

void HAL_SPI_RxCpltCallback(SPI_HandleTypeDef *hspi)
{
	if (hspi->Instance == SPI3) {
		spi_rx_buffer[pixel_count++] = rx_data;
		if (pixel_count >= sizeof(spi_rx_buffer)) {
			pixel_count = 0;
		}
		HAL_SPI_Receive_IT(&hspi3, &rx_data, 1);
	}
}
#endif

#if 0
uint8_t spi_rx_buffer;
HAL_SPI_Receive_IT(&hspi3, &spi_rx_buffer, 1);

void HAL_SPI_RxCpltCallback(SPI_HandleTypeDef *hspi)
{
	if (spi_rx_buffer == 0xFF) {
		printf("Motion Detected!\n")
	}
		HAL_SPI_Receive_IT(&hspi3, &spi_rx_buffer, 1);
}

#endif

#if 0
uint8_t spi_rx_buffer[320 * 240];
uint32_t pixel_count = 0;

void HAL_SPI_RxCpltCallback(SPI_HandleTypeDef *hspi)
{
	if (hspi->Instance == SPI3) {
		spi_rx_buffer[pixel_count++] = rx_data;

		if (pixel_count >= sizeof(spi_rx_buffer)) {

			t_ds1302 ds_time = get_time_from_ds1302();
			save_data_to_flash(&time, spi_rx_buffer, sizeof(spi_rx_buffer));

			pixel_count = 0;
		}
		HAL_SPI_Receive_IT(&hspi3, &rx_data, 1);
	}
}
#endif
//void start_spi_transfer()
//{
//	HAL_SPI_Receive_IT(&hspi3, spi_rx_buffer, sizeof(spi_rx_buffer));
//}
