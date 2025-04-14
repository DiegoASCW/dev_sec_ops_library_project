<?php
session_start();
header('Content-Type: image/jpeg');

$text = rand(10000, 99999);
$_SESSION["vercode"] = $text;

$height = 30;
$width = 80;
$image_p = imagecreate($width, $height);

// Improved color scheme
$background = imagecolorallocate($image_p, 240, 240, 240);
$text_color = imagecolorallocate($image_p, 0, 0, 0);
$noise_color = imagecolorallocate($image_p, 150, 150, 150);

// Add some noise/dots for better security
for ($i = 0; $i < 100; $i++) {
    imagesetpixel($image_p, rand(0, $width), rand(0, $height), $noise_color);
}

// Draw the text
imagestring($image_p, 5, 15, 7, $text, $text_color);

// Output and cleanup
imagejpeg($image_p, null, 80);
imagedestroy($image_p);
exit();
?>