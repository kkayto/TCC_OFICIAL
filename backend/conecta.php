<?php
$host = 'localhost';
$user = 'root';
$password = '';
$dbname = 'bancoREPRE';

$conect = mysqli_connect($host, $user, $password, $dbname);

function login($conect)
{
    if (isset($_POST['entrar']) and !empty($_POST['email']) and !empty($_POST['senha'])) {

        $email = filter_input(INPUT_POST, "email", FILTER_VALIDATE_EMAIL);
        $senha = sha1($_POST['senha']);
        $query = "SELECT * FROM alunos WHERE email = '$email' AND  senha = '$senha'";
        $executaQuery = mysqli_query($conect, $query);
        $return = mysqli_fetch_assoc($executaQuery);

        if(!empty($return['email'])) {
            echo "Bem vindo " .$return ['nome'];

            session_start();
            $_SESSION['nome'] = $return['nome'];
            $_SESSION['id'] = $return['id'];
            $_SESSION['ativo'] = TRUE;
        } else {
            echo "Usuario ou senha nao encontrados.";
        }
    }
}

?>