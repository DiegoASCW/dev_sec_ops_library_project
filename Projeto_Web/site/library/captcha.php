<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

session_start();
header('Content-Type: image/jpeg');

$text = rand(10000, 99999);
$_SESSION["vercode"] = $text;

$height = 30;
$width = 100;
$image_p = imagecreate($width, $height);

// Cores
$background = imagecolorallocate($image_p, 240, 240, 240);
$text_color = imagecolorallocate($image_p, 0, 0, 0);
$noise_color = imagecolorallocate($image_p, 150, 150, 150);

// Ruído
for ($i = 0; $i < 100; $i++) {
    imagesetpixel($image_p, rand(0, $width - 1), rand(0, $height - 1), $noise_color);
}

// Texto
imagestring($image_p, 5, 20, 7, $text, $text_color);

// Output
imagejpeg($image_p, null, 80);
imagedestroy($image_p);
exit();
?>
