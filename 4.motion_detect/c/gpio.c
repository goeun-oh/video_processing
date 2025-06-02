/*
 * gpio.c
 *
 *  Created on: Mar 25, 2025
 *      Author: kccistc
 */

#include "main.h"

void HAL_GPIO_EXTI_Callback(uint16_t GPIO_Pin);

//void HAL_GPIO_EXTI_Callback(uint16_t GPIO_Pin)
//{
//	if (GPIO_Pin == Motion_Detected_Pin) {
//
//		printf("Motion Detected!\n");
//		//start_spi_transfer();
//	}
//}
