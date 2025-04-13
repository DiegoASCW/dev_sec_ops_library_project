<?php
session_start();
header('Content-Type: image/jpeg');

$text = rand(10000, 99999);
$_SESSION["vercode"] = $text;

$width = 80;
$height = 30;
$image_p = imagecreate($width, $height);

// Paleta de cores melhorada
$background = imagecolorallocate($image_p, 240, 240, 240);
$text_color   = imagecolorallocate($image_p, 0, 0, 0);
$noise_color  = imagecolorallocate($image_p, 150, 150, 150);

// Adiciona ruído/dots para melhorar a segurança
for ($i = 0; $i < 100; $i++) {
    imagesetpixel($image_p, rand(0, $width - 1), rand(0, $height - 1), $noise_color);
}

// Desenha o texto
imagestring($image_p, 5, 15, 7, $text, $text_color);

// Gera a imagem e finaliza
imagejpeg($image_p, null, 80);
imagedestroy($image_p);
exit();
?>
