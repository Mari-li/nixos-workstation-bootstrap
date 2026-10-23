# PHP 8.5. OPcache is built into PHP 8.5 itself (php85Extensions has no
# separate opcache attribute), so it is not listed below.
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    (php85.withExtensions ({ enabled, all }: enabled ++ [
      all.pdo
      all.pdo_pgsql
      all.pdo_mysql
      all.mysqli
      all.mbstring
      all.pgsql
      all.intl
      all.zip
      all.curl
      all.xsl
      all.redis
      all.amqp
      all.ds   # php-ds 2.x: Ds\Seq, Ds\Map, Ds\Set, Ds\Heap, Ds\Pair (no 1.x Vector/Deque)
    ]))
    php85Packages.composer

    # PHP language servers for Zed's "php" extension, which prefers binaries
    # found on PATH over downloading its own copies.
    intelephense
    phpactor
  ];
}
