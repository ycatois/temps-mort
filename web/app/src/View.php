<?php
declare(strict_types=1);

namespace TempsMort;

/** Gabarits PHP natifs : chaque page est rendue dans templates/layout.php. */
final class View
{
    /** @param array<string,mixed> $config */
    public function __construct(private readonly string $dir, private readonly array $config) {}

    /** @param array<string,mixed> $data */
    public function page(string $template, array $data = [], int $status = 200): Response
    {
        $data += ['config' => $this->config, 'title' => $this->config['brand'], 'description' => '', 'current' => ''];
        $data['content'] = $this->partial('pages/' . $template, $data);
        return new Response($this->partial('layout', $data), $status);
    }

    /** @param array<string,mixed> $data */
    public function partial(string $template, array $data = []): string
    {
        $data += ['config' => $this->config];
        $file = $this->dir . '/' . $template . '.php';
        $render = static function (string $__file, array $__data): string {
            extract($__data, EXTR_SKIP);
            ob_start();
            require $__file;
            return (string) ob_get_clean();
        };
        return $render($file, $data);
    }
}
