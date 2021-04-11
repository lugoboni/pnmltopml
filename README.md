# pnmltopml

Neste repositório encontra-se o código para o tradutor de arquivos de Redes de Petri Aninhadas no formano PNML NestedSpin para PML.

<h2>Requisitos</h2>

Os protótipos foram escritos em Python 3 de forma a serem executados em linha de comando.
O Python 3 pode ser obtido no seguinte endereço: https://www.python.org/downloads/

Para executar o código PROMELA é necessário a instalação do SPIN Model Checker (http://spinroot.com/spin). 
Um guia completo de instação do SPIN pode ser encontrado no seguinte endereço: http://spinroot.com/spin/Man/README.html
A versão recomendada para execução dos modelos pml gerados por este tradutor é a 6.4.9  que pode ser encontrada em conjunto com a versão 6.5.0 em: https://github.com/nimble-code/Spin/releases

<h2>Executando tradutor</h2>

Este protótipo funciona com redes de Petri Aninhadas, contudo, ele requer que cada rede esteja escrita em um arquivo PNML diferente.

Para executar o tradutor o código deve ser executado passando-se como argumento os arquivos PNML da rede a ser traduzida, a rede sistema deve ser a primeira da lista e as redes devem ser passadas sem o path, apenas com o nome da rede:

<tt> python ..src/pnmltopmlexecutor.py SN.pnml A.pnml B.pnml </tt>

O tradutor irá gerar um arquivo PML chamado NetTranslated.pml e alguns logs da tradução.

Para executar o código PML basta utilizá-lo como entrada do SPIN. O SPIN irá gerar o relatório da execução da rede.

<tt> spin NetTranslated.pml </tt>
