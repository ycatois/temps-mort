<?php
declare(strict_types=1);

namespace TempsMort\Mail;

/** Envoi d'un e-mail texte. Production : mail() d'o2switch ; local : Mailpit en SMTP ; tests : en mémoire. */
interface Mailer
{
    public function send(string $to, string $subject, string $body): void;
}
