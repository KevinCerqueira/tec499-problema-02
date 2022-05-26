# [TEC499] - Problema 02: Interface E/S
Este projeto tem como intuito a implementação de um protótipo de sensor para medição de temperatura e umidade do ambiente (DHT11) Na fase de protótipo do projeto foi utilizada uma plataforma baseada em FPGAs para confecção dos sensores, mais especificamente a Mercúrio Ciclone IV. O sistema é comandado por um Single Board Computer (SBC), no caso a Raspberry PI Zero. Cada operação de leitura ou monitoramento é interpretada pela FPGA, que por meio da UART se comunica com o SBC.


## Recursos
Kit de desenvolvimento Mercúrio IV
FPGA Cyclone IV
Raspberry Pi Zero
Sensor DHT11

# Projeto
O nosso projeto consiste em duas partes, a da SBC (Raspberry Pi Zero) e a da FPGA (Mercúrio Cyclone IV).

## SBC (Raspberry Pi Zero)


## FPGA
 

## Recebendo dados via UART através da FPGA
O módulo UART RX é responsável por implementar a recepção de dados na UART da FPGA. Ele possui duas entradas, duas saídas, e um parâmetro, sendo estes, respectivamente: Clock: pulso de clock RX_Serial: Dado serial RX_Byte: Byte com os 8 bits recebidos Clock por bit: é necessário para que faça com que a UART da Raspberry e da FPGA funcionem na mesma frequência. Para definir o valor deste parâmetro calcula-se o quociente entre a frequência da placa e o baud rate. [Frequência/Baud Rate = 50MHz/7200]).
Para realizar a sincronização entre essas duas entidades (Raspberry e FPGA), utiliza-se esse valor como parâmetro para controlar um contador que definirá se já é ou não possível identificar o bit que está sendo recebido. Nesse contexto, quando ocorre a variação de 3603 ciclos de clocks da placa, significa que já se consegue realizar tal identificação, ou seja, já houve tempo suficiente para que o bit tenha sido recebido.

Nesse módulo existe uma FSM que possui 4 estados:

IDLE:
Tem a função de zerar todos os registradores. Nesse estado, uma estrutura condicional verifica se a entrada de dados RXData recebeu o bit 0 (que representa o Start Bit). Em caso afirmativo, a máquina vai para o próximo estado RX Data Bits. Em caso negativo, a máquina se mantém nesse estado até que essa situação ocorra.

RX_DATA_BITS: Enquanto não ocorre a quantidade de variações necessárias para a recepção de um bit (6944 ciclos de clock), um registrador que atua como contador é acrescido em 1. Sabendo que o dado que está sendo recebido tem o tamanho de 1 byte, cria-se um registrador chamado RX_Byte para armazenar este. A cada bit recebido - ou seja, a cada 6944 ciclos de clock - um registrador de 3 bits denonimado Bit_idx é acrescido em 1, e este bit recebido é atribuido ao RX_Byte na posição indicada por Bit_idx. Para garantir que os 8 bits já foram recebidos, uma estrutura condicional verifica se Bit_idx é menor que 7 (tamanho máximo que este pode assumir). Em caso afirmativo, os bits não foram todos recebidos, portanto, incrementa-se 1 ao index e a máquina de estados volta novamente para o estado de recepção de dados (RX_Data_Bits). Em caso negativo, atribui-se 0 ao index e a FSM segue para o estado de recepção do stop bit.

RX STOP BIT A lógica de funcionamento desse estado é semelhante ao RX START BIT. O valor de um registrador que funciona como um contador é comparado com o valor do parâmetro Clock por bit definido anteriormente. Se o contador for diferente da quantidade de clocks por bits, ele é incrementado em um até que essa igualdade ocorra. Posteriormente, quando o contador estiver alcançado o valor exato do clock por bit definido, atribui-se um nível lógico alto para o registrador Done, o contador pode ser resetado e a máquina pode seguir para o próximo estado RESET.

RESET: É responsável por enviar a máquina para o estado IDLE, e atribuir 0 para o registrador Done.

