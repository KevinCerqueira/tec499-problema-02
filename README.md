# [TEC499] - Problema 02: Interface E/S
Este projeto tem como intuito a implementação de um protótipo de sensor para medição de temperatura e umidade do ambiente (DHT11) Na fase de protótipo do projeto foi utilizada uma plataforma baseada em FPGAs para confecção dos sensores, mais especificamente a Mercúrio Ciclone IV. O sistema é comandado por um Single Board Computer (SBC), no caso a Raspberry PI Zero. Cada operação de leitura ou monitoramento é interpretada pela FPGA, que por meio da UART se comunica com o SBC.

# Equipe:
- Esdras Abreu
- Guilherme Nobre
- Kevin Cerqueira

## Recursos
- Kit de desenvolvimento Mercúrio IV
- FPGA Cyclone IV
- Raspberry Pi Zero
- Sensor DHT11

# Elucidando comunição envolvendo FPGA

## Máquina de estados DHT11 na FPGA

//bloco de inicialização
IDLE: Habilita canal para envio e coloca a porta em modo saída e envia um sinal alto.
START_0 = Envia um sinal baixo por 18ms para iniciar comunicação.
START_1 = Manda um sinal alto de 20us.
RESPONCE = Aguarda 60us de delay ou até o canal for alterado pelo sensor

//bloco de sincronização		
SYNC_0 = Aguarda 80us de sinal baixo enviado pelo sensor
SYNC_1 = //Aguarda 80us de sinal alto enviado pelo sensor

//leitura de dados do canal do sensor
DATA = Conta o tempo de cada pulso alto que segue um pulso baixo, ressaltando que pulsos maiores que 50us significam '1' e pulsos menores que 30us significam '0'

STOP = Envia sinal de finalização da leitura do sensor  
ERROR = Fecha leitura do canal e coloca-o em sinal alto

## Recebendo dados via UART através da FPGA
O módulo UART8RECEIVER é responsável por implementar a recepção de dados na UART da FPGA. Ele possui três entradas, três saídas. Para sincronização da comunicação é necessário fazer com que a UART da Raspberry e da FPGA funcionem na mesma frequência. Para definir o valor deste parâmetro calcula-se o quociente entre a frequência da placa e o baud rate. [Frequência/Baud Rate = 50MHz/7200]).
Na sincronização entre essas duas entidades (Raspberry e FPGA), utiliza-se esse valor como parâmetro para controlar um contador que definirá se já é ou não possível identificar o bit que está sendo recebido. Nesse contexto, quando ocorre a variação de 6944 ciclos de clocks da placa, significa que já se consegue realizar tal identificação, ou seja, já houve tempo suficiente para que o bit tenha sido recebido.

Nesse módulo existe uma FSM que possui 4 estados:

IDLE:
Tem a função de zerar todos os registradores. Nesse estado, uma estrutura condicional verifica se a entrada de dados RXData recebeu o bit 0 (que representa o Start Bit). Em caso afirmativo, a máquina vai para o próximo estado Data Bits. Em caso negativo, a máquina se mantém nesse estado até que essa situação ocorra.

DATA_BITS: Enquanto não ocorre a quantidade de variações necessárias para a recepção de um bit (6944 ciclos de clock), um registrador que atua como contador é acrescido em 1. A cada bit recebido - ou seja, a cada 6944 ciclos de clock - um registrador de 3 bits denonimado Bit_idx é acrescido em 1, e este bit recebido é atribuido ao RX_Byte na posição indicada por Bit_idx. Para garantir que os 8 bits já foram recebidos, uma estrutura condicional verifica se Bit_idx é menor que 7 (tamanho máximo que este pode assumir). Em caso afirmativo, os bits não foram todos recebidos, portanto, incrementa-se 1 ao index e a máquina de estados volta novamente para o estado de recepção de dados (RX_Data_Bits). Em caso negativo, atribui-se 0 ao index e a FSM segue para o estado de recepção do stop bit.

STOP BIT A lógica de funcionamento desse estado é semelhante ao START BIT. O valor de um registrador que funciona como um contador é comparado com o valor do parâmetro Clock por bit definido anteriormente. Se o contador for diferente da quantidade de clocks por bits, ele é incrementado em um até que essa igualdade ocorra. Posteriormente, quando o contador estiver alcançado o valor exato do clock por bit definido, atribui-se um nível lógico alto para o registrador Done, o contador pode ser resetado e a máquina pode seguir para o próximo estado RESET.

RESET: É responsável por enviar a máquina para o estado IDLE, e atribuir 0 para o registrador Done.

## Enviando dados via UART através da FPGA
O módulo UART8TRANSMITTER é responsável por implementar a lógica de envio de dados na UART da FPGA. Ele possui um parâmetro, três entradas e três saídas, sendo estes, respectivamente: Clock por bit: Esse parâmetro existe neste módulo pelo mesmo motivo de estar presente no módulo de recepção. No entanto, este valor é utilizado para controlar um contador que definirá se já é ou não possível enviar o bit desejado. Nesse contexto, quando ocorre a variação de 6944 ciclos de clocks da placa, significa que já se consegue realizar tal envio, ou seja, já houve tempo suficiente para que o bit tenha sido enviado.

Nesse módulo existe uma FSM que possui 4 estados:

IDLE:
Tem a função de zerar todos os registradores, exceto à saída, a qual tem nível lógico alto atribuído, para que quando a transmissão se inicie no estado posterior, seja possível reconhecer o Start Bit como 0. Nesse estado, uma estrutura condicional verifica se a entrada de dados recebeu o bit 1. Em caso afirmativo, significa que irá iniciar uma transmissão de dados, portanto, atribui-se o valor que deseja transmitir a um registrador e a máquina segue para o estado de envio do Start Bit. Em caso negativo, a máquina se mantém no estado IDLE até que a situação descrita anteriormente ocorra.

START BIT:
Nesse estado, como se sabe que o start bit é 0, inicialmente atribui-se nível lógico baixo à saída. Posteriormente, o valor de um registrador que funciona como um contador é comparado com o valor do parâmetro Clock por bit definido anteriormente para garantir que o envio está sendo realizado sob a frequência necessária. Se o contador for diferente da quantidade de clocks por bits, ele é incrementado em um até que essa igualdade ocorra. Quando essa situação ocorrer, a FSM vai para o estado DATA_BITS para envio de dados.

DATA_BITS:
Inicialmente atribui-se à saídao bit referente ao byte que deve ser enviado, o qual está localizado no index 0 do registrador de 8 bits data. Enquanto não ocorre a quantidade de variações de clock necessárias para a envio de um bit, um registrador que atua como contador é acrescido em 1 e a máquina vai para o mesmo estado atual denominado DATA BITS. Quando o contador alcança 6944, significa que o primeiro bit já foi transmitido e, portanto, já é possível enviar o próximo bit. Para isso, o registrador que atua como contador é zerado e verifica-se se o bitIdx é menor que 7 (tamanho máximo que este pode assumir). Em caso afirmativo, os bits não foram todos enviados, portanto, incrementa-se 1 ao index e a máquina de estados volta novamente para o estado de transmissão de dados (Data_Bits) para que possa enviar o bit da próxima posição. Em caso negativo, atribui-se 0 ao index e a FSM segue para o estado de envio do stop bit.

STOP BIT:
Inicialmente, atribui-se nível lógico alto à saída, o qual representa o Stop Bit. Posteriormente, o valor de um registrador que funciona como um contador é comparado com o valor do parâmetro Clock por bit definido anteriormente. Se o contador for diferente da quantidade de clocks por bits, ele é incrementado em um até que essa igualdade ocorra. Posteriormente, quando o contador estiver alcançado o valor exato do clock por bit definido, atribui-se um nível lógico alto para o registrador Done (que irá representar que o a transmissão do byte está completa), o contador pode ser resetado e a máquina pode seguir novamente para o estado IDLE.

## Interface com o usuário

Foi feito um código em C para comunicar o SBC com a FPGA. Nesse código, bibliotecas em assembly desenvolvidas no problema 1 do MI sao utlizadas para configurar a UART do SBC. Depois, o usuário pode inserir um número através da função scanf(). Finamente, o comando é guardado e enviado e transmitido através de outra biblioteca assembly, e uma resposta é recebida e guardada.
