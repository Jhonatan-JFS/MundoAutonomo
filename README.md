# Mundo Autônomo — Android 0.1.1

Simulador experimental de mundos e civilizações para Android, feito em **Godot 4.5.2 / GDScript**, com pixel art procedural. Projeto independente; não reutiliza nem modifica os demais repositórios.

## Versão jogável 0.1.1

- Mundo de 96 × 96 células criado proceduralmente a partir de uma semente.
- Duas comunidades fictícias: Aurora e Crepúsculo, com 18 habitantes iniciais.
- Habitantes exploram, procuram alimentos e madeira, envelhecem, podem morrer ou nascer; aldeias constroem novas moradias.
- Ferramentas de edição: terra, água, floresta, montanhas e criar habitante.
- Controles: toque/arrasto para editar, modo Mover mapa para deslocar a câmera, pinça para ampliar, modo Inspecionar para conferir informações.
- Velocidades: pausa, 1×, 2× e 4×.
- Salvar restaura o mundo no dispositivo da próxima vez em que o jogo for aberto.

## Instalar no Android

O APK de depuração está disponível no GitHub Actions: [compilação aprovada](https://github.com/Jhonatan-JFS/MundoAutonomo/actions/runs/44516900370).

1. Abra a execução vinculada acima.
2. Em **Artifacts**, baixe `MundoAutonomo-0.1.1-Android-APK`.
3. Extraia o APK do arquivo ZIP obtido.
4. Instale no celular Android ARM64, permitindo instalar aplicativos a partir da origem escolhida quando o Android solicitar.

O artifact tem retenção configurada em 30 dias. Ao atualizar o código da branch `main`, o workflow produzirá nova tentativa de exportação.

## Validação e limitações

A execução de CI passou em 19/11/2026: importação dos scripts, testes automatizados com 120 ciclos, teste de inicialização headless, exportação Android e verificação de integridade do APK. **Os controles de toque e o desempenho ainda precisam ser testados em um aparelho físico**.

Esta é uma versão inicial de curiosidade e testes, não um jogo completo. Ainda faltam guerra, diplomacia, tecnologia, biomas avançados e otimizações para populações grandes.

## Desenvolvimento

O workflow está em `.github/workflows/android-debug.yml`, as cenas em `scenes/`, os scripts em `scripts/` e os testes em `tests/`. O preset Android está em `export_presets.cfg`. O aplicativo não precisa de internet nem solicita permissão de rede.

Para executar no PC: abra este diretório no Godot 4.5.2 e pressione F5.
