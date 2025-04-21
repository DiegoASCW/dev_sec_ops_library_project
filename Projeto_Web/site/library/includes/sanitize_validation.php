<?php
// Função para converter para ASCII simples
function sanitize_string_ascii($string) {
    $string = iconv('UTF-8', 'ASCII//TRANSLIT//IGNORE', $string);

    // Remove qualquer caractere que não seja letra, número, vírgula, hífen
    $string = preg_replace('/[^\\x30-\\x39\\x41-\\x5A\\x61-\\x7A\\x2C\\x2D]/', '', $string);

    return $string;
}


// Função para detectar injeção de código XSS ou SQLi
function is_injection($input) {
    $patterns = [
        '/(select|union|insert|update|delete|drop|--|;|or\s+1=1)/i', // SQLi
        '/<script[^>]*>.*?<\/script>/i', // XSS básico
        '/on\w+\s*=\s*["\']?.*?["\']?/i', // Atributos JS como onclick, onerror
        '/(alert|prompt|confirm)\s*\(/i' // Funções JS potencialmente perigosas
    ];

    foreach ($patterns as $pattern) {
        if (preg_match($pattern, $input)) {
            return true;
        }
    }

    return false;
}
?>
