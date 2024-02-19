# Donate-alerts-and-commands
Plugin para ativação de comandos através de donate de jogadores!

## Comandos:
- ```sm_give <weaponname>```:
  Dê uma arma para todos os jogadores vivos.
  
---
* ```sm_give2 <weaponname>```:
  Dê duas armas para todos os jogadores vivos.  
  Use apenas armas que podem ser equipadas nas duas mãos ao mesmo tempo, como pistolas.  
  Se você tentar usar o 'give2' para rifles, por exemplo, a segunda arma será derrubada automaticamente.
  
---
* ```sm_givelist```:
  Exibe uma lista com todas as armas disponíveis.
  
---
* ```sm_alert <color> <text>```:
  Envie mensagens para todos os jogadores com cores e com a possibilidade de pular para a próxima linha.
  Exemplo:
  ```sm_alert {red} Olá\n{blue}Mundo!```
