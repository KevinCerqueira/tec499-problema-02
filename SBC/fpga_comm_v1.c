#include <stdio.h>
#include <time.h>

void delay(int ms){
	long pause;
	clock_t now, then;
	pause = ms*(CLOCKS_PER_SEC/1000);
	while( (now-then) < pause);
		now = clock();
}

extern void map_mem();
extern void set_uart();
extern void put_data(); 

int main(){
	int delay_time;
	
	printf("Your delay time?");
	/* scanf("%d", delay_time); */

	map_mem();
	/* printf("Your life is worthless!\n"); */

	set_uart();
	/* printf("You serve ZERO purpose!\n"); */

	asm("mov r6, #5");
	while(1){
		put_data();
		printf("You should kill yourself... NOW!\n");
		delay(1000);
		
	}
	/* printf("You should kill yourself... NOW!\n"); */

	return 0;
}
