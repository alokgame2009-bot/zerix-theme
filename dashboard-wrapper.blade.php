<script>
(function () {
  document.documentElement.classList.add('zerix-v3');
  const saved = localStorage.getItem('zerix-accent');
  if (saved) document.documentElement.style.setProperty('--zx-accent', saved);
})();
</script>
