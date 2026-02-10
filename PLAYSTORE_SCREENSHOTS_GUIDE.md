# 📱 Guia de Screenshots para Google Play Store - Ana Mercado

## Especificações Baseadas no Código Real do App

Este guia documenta EXATAMENTE como o app Ana Mercado aparece, baseado na análise do código fonte.

---

## 🎨 Paleta de Cores do App (Código Real)

### Cores Principais:
- **Azul Primário**: `Colors.blue.shade900` → `Colors.blue.shade500` (Gradiente)
- **Azul AppBar**: `Colors.blue.shade700` / `Colors.blue.shade800`
- **Azul Botões**: `Colors.blue.shade600`
- **Verde (Finalizar)**: `Colors.green`
- **Vermelho (Excluir)**: `Colors.red`
- **Branco**: `Colors.white` (Fundos de cards)
- **Cinza (Textos secundários)**: `Colors.grey.shade600` / `Colors.grey.shade400`

### Modo Escuro:
- **Fundo**: `#1E1E1E`
- **Cards**: `#2C2C2C`
- **Azul Claro**: `Colors.lightBlueAccent`

---

## 📸 Screenshot 1: SPLASH SCREEN (Tela Inicial)

### Layout:
- **Fundo**: Branco puro
- **Centro**: Ícone de carrinho de compras azul (60px) dentro de um círculo branco com sombra azul
- **Animação**: Carrinho desliza da esquerda puxando uma linha azul
- **Texto Principal**: "Ana Mercado" (36px, negrito, azul, espaçamento 1.2)
- **Subtítulo**: "Sempre com você!" (16px, azul claro)
- **Loading**: CircularProgressIndicator azul (30x30px)

```
Elementos visuais:
┌────────────────────────┐
│                        │
│         [Carrinho]     │
│      ════════════      │ (linha sendo puxada)
│                        │
│     Ana Mercado        │
│   Sempre com você!     │
│                        │
│         (●)            │ (loading)
└────────────────────────┘
```

---

## 📸 Screenshot 2: LOGIN SCREEN

### Layout:
- **Fundo**: Gradiente linear de `Colors.blue.shade900` (topo esquerda) até `Colors.blue.shade500` (baixo direita)
- **Topo**: Ícone carrinho azul branco (80px)
- **Título**: "Ana Mercado" (32px, fonte Poppins, negrito, branco)
- **Subtítulo**: "Suas compras, mais fáceis." (16px, branco 70% opacidade)

### Card Central (Branco com elevação 12):
- **Borda**: 24px arredondada
- **Título**: "Bem-vindo de volta" (20px, Poppins, cinza escuro 800)
- **Campo Email**:
  - Label: "Email"
  - Hint: "exemplo@email.com"
  - Ícone: `Icons.email_outlined` (azul)
  - Fundo: `Colors.grey.shade50`
  - Borda: 12px arredondada
- **Campo Senha**:
  - Label: "Senha"
  - Ícone: `Icons.lock_outline` (azul)
  - Ícone direita: `Icons.visibility_outlined` (cinza)
  - Fundo: `Colors.grey.shade50`
- **Botão ENTRAR**:
  - Altura: 54px
  - Cor: `Colors.blue.shade600`
  - Texto: "ENTRAR" (16px, Poppins, negrito, branco)
  - Borda: 14px arredondada
- **Texto inferior**: "Não tem uma conta?" (cinza 600) + "Cadastre-se" (azul 800, negrito)
- **Rodapé**: "Versão 1.0.0" (branco 50% opacidade)

---

## 📸 Screenshot 3: HOME SCREEN (Lista de Compras)

### AppBar (Gradiente azul 800 → azul 500):
- **Altura**: 80px
- **Ícone Menu**: `Icons.menu` (branco, esquerda)
- **Título Principal**: "Olá, [Nome]" (20px, negrito, branco)
- **Subtítulo**: "Seja bem-vindo" (14px, branco 70%)
- **Ícone Notificação**: `Icons.notifications_outlined` com badge vermelho se houver novas
- **Foto Perfil**: Círculo 40px (borda branca 2px) - mostra imagem ou primeira letra

### Cards de Listas:
- **Elevação**: 3
- **Margem**: 16px inferior
- **Borda**: 15px arredondada
- **Título**: Nome da lista (18px, negrito)
- **Botão**: "Finalizar Lista" (verde, outline, 20px arredondado)
- **Rodapé 3 colunas**:
  - "Não marcados": R$ [valor] (cinza 600)
  - "Marcados": R$ [valor] (verde)
  - "Total": R$ [valor] (azul 800/300)

### FAB (Floating Action Button):
- **Texto**: "Nova Lista"
- **Ícone**: `Icons.add`
- **Cor**: Azul padrão

---

## 📸 Screenshot 4: LIST DETAIL SCREEN (Detalhes da Lista)

### AppBar:
- **Título**: Nome da lista
- **Cor**: `Colors.blue.shade700` (barra azul sólida)

### Card Resumo (azul 50 / #2C2C2C escuro):
- **Padding**: 16px
- **Linha 1**: "Total da Compra: R$ [valor]" (16px, marcados)
- **Linha 2**: "Carrinho: R$ [valor]" (20px, negrito, azul) - não marcados

### Lista de Itens:
- **Checkbox**: Azul (light blue no escuro)
- **Nome**: Texto com strikethrough se marcado (cinza se marcado)
- **Subtítulo**: "[qtd]x R$ [preço] = R$ [total] + [Categoria]" (cinza)
- **Ícones**: Editar (azul), Excluir (cinza)
- **Dismissible**: Fundo vermelho com ícone delete (deslizar para excluir)

### FAB:
- **Texto**: "Adicionar Item"
- **Ícone**: `Icons.add_shopping_cart`
- **Posição**: centerFloat

---

## 📸 Screenshot 5: DASHBOARD SCREEN (Estatísticas)

### AppBar:
- **Título**: "Dashboard"
- **Cor**: `Colors.blue.shade700`
- **Texto**: Branco

### Filtro de Mês:
- **Container**: Branco com borda azul 200
- **Borda**: 12px arredondada
- **Ícone**: `Icons.calendar_month` (azul)
- **Texto**: "Geral (Até Agora)" ou "[Mês] [Ano]"
- **Seta**: `Icons.keyboard_arrow_down` (cinza)

### Card 1 - Gastos por Categoria:
- **Elevação**: 4
- **Borda**: 16px arredondada
- **Título**: "Gastos por Categoria" (18px, negrito)
- **Gráfico**: PieChart (pizza) com:
  - Cores dinâmicas por categoria
  - Centro vazio (radius 40)
  - Valores em R$ nas fatias
  - Legenda colorida abaixo

### Card 2 - Histórico Mensal:
- **Título**: "Histórico Mensal" (18px, negrito)
- **Gráfico**: BarChart (barras) com:
  - Barras azuis (width 20, borda 4px)
  - Tooltip com mês e valor
  - Eixo X: meses (MM)
  - Eixo Y: valores
  - Grid horizontal

---

## 📸 Screenshot 6: CATEGORY MANAGEMENT SCREEN

### AppBar:
- **Título**: "Gerenciar Categorias"

### Fundo:
- **Claro**: `#F2F2F7`
- **Escuro**: `#1E1E1E`

### Lista de Categorias (Cards):
- **Cor Card**: Branco / `#2C2C2C`
- **Avatar**: Círculo com cor da categoria + primeira letra (branco)
- **Nome**: Texto da categoria
- **Ícones**: Editar (azul), Excluir (vermelho)

### FAB:
- **Ícone**: `Icons.add`
- **Cor**: Azul
- **Cor Ícone**: Branco

---

## 📸 Screenshot 7 (Opcional): DRAWER (Menu Lateral)

### Header:
- **Cor**: `Colors.blue.shade700`
- **Foto**: 72px círculo (branco, borda 2px)
- **Nome**: Negrito, 18px, branco
- **Email**: Texto branco

### Itens de Menu:
1. **Dashboard**: `Icons.bar_chart`
2. **Histórico de Compras**: `Icons.history`
3. **Configurações**: `Icons.settings`
4. **Sugerir Melhorias**: `Icons.lightbulb_outline`
5. **Divider**
6. **Sair**: `Icons.exit_to_app` (vermelho)

---

## 🎯 Instruções para Criação dos Screenshots

### Opção 1: Usar o App Real em Emulador
1. Abra o emulador Android (Android Studio ou similar)
2. Instale o APK: `app-release.apk`
3. Capture screenshots nativos (Ctrl+S no emulador)
4. Redimensione para 1080 x 1920px (9:16)

### Opção 2: Usar Ferramenta de Design
1. Use Figma, Adobe XD ou similar
2. Crie frames 1080 x 1920px
3. Replique os designs acima EXATAMENTE como documentado
4. Exporte como PNG de alta qualidade

### Opção 3: Screenshots do Browser (Web Version)
1. Execute `python app.py`
2. Acesse http://localhost:5000
3. Use DevTools do Chrome (F12)
4. Device Mode: iPhone 14 Pro (393 x 852) ou similar
5. Capture screenshots (Ctrl+Shift+P → "Capture screenshot")
6. Redimensione para 1080 x 1920px

---

## ✅ Checklist de Qualidade

Para cada screenshot:
- [ ] Resolução: 1080 x 1920px (mínimo)
- [ ] Formato: PNG ou JPEG
- [ ] Cores exatas conforme documentado
- [ ] Textos legíveis e nítidos
- [ ] Sem bordas de dispositivo (apenas o app)
- [ ] UI completa (sem elementos cortados)
- [ ] Dados de exemplo realistas
- [ ] Sem informações pessoais reais

---

## 📋 Ordem Recomendada para Upload

1. **Splash Screen** - Primeira impressão
2. **Login Screen** - Entrada no app
3. **Home Screen** - Lista de compras
4. **List Detail** - Funcionalidade principal
5. **Dashboard** - Estatísticas visuais
6. **Categories** - Organização
7. **History** - Acompanhamento (opcional)

---

## 🚀 Dicas para Google Play Store

### Descrição Curta (80 caracteres):
"Organize suas compras com controle total de gastos e categorias"

### Descrição Completa (4000 caracteres):
```
🛒 Ana Mercado - Suas Compras Mais Fáceis!

Organize suas compras de supermercado de forma inteligente com o Ana Mercado. 
Controle seus gastos em tempo real, organize produtos por categorias e nunca 
mais esqueça nada no mercado!

✨ PRINCIPAIS RECURSOS:

📝 LISTAS INTELIGENTES
• Crie múltiplas listas de compras
• Adicione produtos com quantidade, preço e categoria
• Marque itens conforme você compra
• Edite ou exclua facilmente

💰 CONTROLE DE GASTOS
• Veja o valor total da sua compra em tempo real
• Acompanhe quanto já está no carrinho
• Compare valores planejados vs. realizados

📊 ESTATÍSTICAS DETALHADAS
• Gráficos de gastos por categoria
• Histórico mensal de compras
• Análise visual de tendências
• Filtre por período

🏷️ CATEGORIAS PERSONALIZADAS
• Organize produtos por categorias
• Crie categorias personalizadas
• Cores distintas para fácil identificação

📈 HISTÓRICO COMPLETO
• Consulte compras anteriores
• Analise seus gastos ao longo do tempo
• Reutilize listas anteriores

🔔 NOTIFICAÇÕES
• Receba lembretes importantes
• Novidades e dicas de economia

⚙️ CONFIGURAÇÕES FLEXÍVEIS
• Modo claro e escuro
• Personalize seu perfil
• Controle de privacidade

🔒 SEGURO E PRIVADO
• Seus dados são protegidos
• Login seguro
• Backup automático

Por que escolher o Ana Mercado?

✓ Interface simples e intuitiva
✓ Rápido e eficiente
✓ Sem propagandas intrusivas
✓ Atualizações constantes
✓ Suporte dedicado

Perfeito para:
• Compras de supermercado
• Controle de orçamento familiar
• Organização doméstica
• Economia inteligente

Baixe agora e transforme a forma como você faz compras!

📧 Suporte: suporte@anamercado.com
🌐 Website: www.anamercado.com
```

### Tags/Palavras-chave:
compras, supermercado, lista de compras, controle de gastos, orçamento, 
economia, organização, mercado, carrinho, categorias, estatísticas

---

Criado em: $(date)
Baseado no código fonte real do Ana Mercado
