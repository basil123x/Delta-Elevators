<?php
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
header('Pragma: no-cache');

$path = __DIR__ . '/app_config.json';
if (!is_file($path)) {
    http_response_code(404);
    echo json_encode(['error' => 'missing']);
    exit;
}

readfile($path);
