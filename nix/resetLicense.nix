drv:
drv.overrideAttrs (prev: {
  meta = prev.meta // {
    license = [ ];
  };
})
