{
  tasks = {
    micro_workers = 10;
    macro_workers = 25;
    bizarre_retry = 5;
    image_alloc = 536870912; # 512MB
    image_bound = [
      0
      0
    ];
    suppress_preload = false;
  };
}
