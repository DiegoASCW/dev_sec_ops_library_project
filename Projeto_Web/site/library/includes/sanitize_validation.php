<?php
// Função para converter para ASCII simples
function sanitize_string_ascii($string) {
    $string = iconv('UTF-8', 'ASCII//TRANSLIT//IGNORE', $string);

    // Remove qualquer caractere que não seja letra, número, vírgula, hífen
    $string = preg_replace('/[^\\x30-\\x39\\x41-\\x5A\\x61-\\x7A\\x2C\\x2D]/', '', $string);

    return $string;
}



// Função para detectar injeção de código XSS ou SQLi
function injection_detect($input) {
    $patterns = [
        '/\b(SELECT|UNION|INSERT|UPDATE|DELETE|DROP|--|;|OR\s+1=1)\b/i', // SQLi
        '/<script\b[^>]*>(.*?)<\/script>/i', // XSS
        '/on\w+=["\']?[^"\']+["\']?/i', // Atributos via JS como onclick, onerror, e demais
        '/\b(alert|prompt|confirm)\s*\(/i' // JS malicioso
    ];

    foreach ($patterns as $pattern) {
        if (preg_match($pattern, $input)) {
            return true;
        }
    }
    return false;
}
?>