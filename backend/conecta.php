<?php

$host = 'localhost';
$user = 'tcc_user';
$password = 'SENHA123';
$dbname = 'bancoREPRE';
$port = '3307';

$conect = mysqli_connect(
    $host,
    $user,
    $password,
    $dbname,
    $port
);

if (!$conect) {
    die("Erro ao conectar ao banco: " . mysqli_connect_error());
}

mysqli_set_charset($conect, 'utf8mb4');

function login($conect)
{
    if (
        !isset($_POST['entrar']) ||
        empty($_POST['email']) ||
        empty($_POST['senha'])
    ) {
        return;
    }

    $email = filter_input(
        INPUT_POST,
        'email',
        FILTER_VALIDATE_EMAIL
    );

    $senha = $_POST['senha'];

    if (!$email) {
        echo "E-mail inválido.";
        return;
    }

    $sql = "
        SELECT id, nome, email, senha_hash, ativo, tipo
        FROM alunos
        WHERE email = ?
        LIMIT 1
    ";

    $stmt = mysqli_prepare($conect, $sql);

    if (!$stmt) {
        die("Erro na consulta: " . mysqli_error($conect));
    }

    mysqli_stmt_bind_param($stmt, "s", $email);
    mysqli_stmt_execute($stmt);

    $resultado = mysqli_stmt_get_result($stmt);
    $usuario = mysqli_fetch_assoc($resultado);

    if (!$usuario) {
        echo "Usuário ou senha não encontrados.";
        return;
    }

    if (!password_verify($senha, $usuario['senha_hash'])) {
        echo "Usuário ou senha não encontrados.";
        return;
    }

    if ((int)$usuario['ativo'] !== 1) {
        echo "Este usuário está desativado.";
        return;
    }

    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }

    $_SESSION['nome'] = $usuario['nome'];
    $_SESSION['id'] = $usuario['id'];
    $_SESSION['email'] = $usuario['email'];
    $_SESSION['tipo'] = $usuario['tipo'];
    $_SESSION['ativo'] = true;

    header("Location: ../home.php");
    exit;
}
