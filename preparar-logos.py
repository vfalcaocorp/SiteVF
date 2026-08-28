# -*- coding: utf-8 -*-
r"""
preparar-logos.py — prepara as logos dos clientes para o site.

O que faz com cada arquivo da pasta Logos\:
  1. recorta a margem sobrando (transparente ou de cor uniforme);
  2. deita sobre fundo branco ou preto, conforme a cor da arte;
  3. centraliza numa tela 800x500 igual para todas, com a mesma folga;
  4. salva em web\logos\<nome>.png

A escala e sempre uniforme: nenhuma logo estica ou achata.

Como usar:
    python preparar-logos.py

Para acrescentar um cliente: jogue o arquivo em Logos\, adicione uma linha
em MARCAS abaixo e rode de novo. Depois inclua a marca na lista LOGOS
dentro do index.html.
"""

from PIL import Image
import os
import sys

ORIGEM = 'Logos'
DESTINO = os.path.join('web', 'logos')

# tela final de cada placa (mesma proporcao do CSS: 16/10)
TELA_W, TELA_H = 800, 500
# quanto da tela a arte pode ocupar (o resto vira respiro)
OCUPA_W, OCUPA_H = 0.74, 0.68

BRANCO = (255, 255, 255)
PRETO = (19, 19, 23)          # igual ao .logo.escuro do CSS

# arquivo de origem -> (nome de saida, fundo, modo)
# fundo: 'claro'  = arte escura, vai em placa branca
#        'escuro' = arte clara/branca, vai em placa preta
# modo:  None                 = usa a imagem como esta (respeita transparencia)
#        'branco-sobre-preto' = a arte e branca chapada num fundo preto solido.
#                               Converte o brilho em transparencia, para a arte
#                               assentar na placa sem deixar um retangulo preto.
MARCAS = [
    ('image-1787945504277.png', 'rose-pasteis',     'claro',  None),
    ('Ativo 1-8.png',           'brasa-grill',      'claro',  None),
    ('400X400 2.png',           'triad-caps',       'escuro', 'branco-sobre-preto'),
    ('image-1787945509184.png', 'fcgroup',          'escuro', None),
    ('image-1787945511469.png', 'ceriani-craveiro', 'claro',  None),
    ('image-1787945514172.png', 'andrade',          'claro',  None),
    ('400x200.png',             'placemed',         'claro',  None),
    ('image-1787945507196.png', 'darka',            'claro',  None),
]


def recortar(im):
    """Tira a margem sobrando: por transparencia, ou pela cor das bordas."""
    bbox = im.getchannel('A').getbbox()
    if bbox:
        im = im.crop(bbox)

    # se ainda houver moldura de cor uniforme, tira tambem
    rgb = im.convert('RGB')
    canto = rgb.getpixel((0, 0))
    fundo = Image.new('RGB', rgb.size, canto)
    from PIL import ImageChops
    dif = ImageChops.difference(rgb, fundo).convert('L').point(lambda v: 255 if v > 18 else 0)
    bbox2 = dif.getbbox()
    if bbox2 and (bbox2[2] - bbox2[0]) > 8 and (bbox2[3] - bbox2[1]) > 8:
        im = im.crop(bbox2)
    return im


def brilho_para_alpha(im):
    """Arte branca chapada sobre preto -> arte branca com transparencia.

    Usa o brilho de cada pixel como opacidade, entao as bordas suaves da
    arte continuam suaves e nao sobra retangulo preto na placa.
    """
    rgb = im.convert('RGB')
    alpha = rgb.convert('L')                       # brilho = quanto de tinta
    branco = Image.new('RGB', im.size, (255, 255, 255))
    saida = branco.convert('RGBA')
    saida.putalpha(alpha)
    return saida


def preparar(caminho, fundo, modo=None):
    im = Image.open(caminho).convert('RGBA')
    if modo == 'branco-sobre-preto':
        im = brilho_para_alpha(im)
    im = recortar(im)

    cor = BRANCO if fundo == 'claro' else PRETO

    # escala uniforme para caber na area util
    util_w, util_h = TELA_W * OCUPA_W, TELA_H * OCUPA_H
    escala = min(util_w / im.width, util_h / im.height)
    novo = (max(1, round(im.width * escala)), max(1, round(im.height * escala)))
    im = im.resize(novo, Image.LANCZOS)

    tela = Image.new('RGB', (TELA_W, TELA_H), cor)
    tela.paste(im, ((TELA_W - novo[0]) // 2, (TELA_H - novo[1]) // 2), im)
    return tela, novo


def main():
    raiz = os.path.dirname(os.path.abspath(__file__))
    os.chdir(raiz)

    if not os.path.isdir(ORIGEM):
        print('Pasta "%s" nao encontrada.' % ORIGEM)
        sys.exit(1)
    os.makedirs(DESTINO, exist_ok=True)

    feitos, faltando = 0, []
    for arquivo, nome, fundo, modo in MARCAS:
        origem = os.path.join(ORIGEM, arquivo)
        if not os.path.exists(origem):
            faltando.append(arquivo)
            continue
        tela, tam = preparar(origem, fundo, modo)
        saida = os.path.join(DESTINO, nome + '.png')
        tela.save(saida, optimize=True)
        print('  %-18s fundo %-7s arte %dx%d  ->  %s' % (nome, fundo, tam[0], tam[1], saida))
        feitos += 1

    print('')
    print('%d logos prontas em %s' % (feitos, DESTINO))
    if faltando:
        print('Nao encontrei: %s' % ', '.join(faltando))


if __name__ == '__main__':
    main()
