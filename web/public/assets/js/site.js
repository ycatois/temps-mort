// Bascule mensuel / saison sur la page Tarifs (amélioration progressive : sans JS, le tarif saison s'affiche).
document.querySelectorAll('[data-billing-toggle]').forEach((group) => {
  const buttons = group.querySelectorAll('[data-billing]');
  const apply = (mode) => {
    buttons.forEach((b) => b.setAttribute('aria-pressed', String(b.dataset.billing === mode)));
    document.querySelectorAll('[data-price-month]').forEach((el) => { el.hidden = mode !== 'month'; });
    document.querySelectorAll('[data-price-season]').forEach((el) => { el.hidden = mode !== 'season'; });
  };
  buttons.forEach((b) => b.addEventListener('click', () => apply(b.dataset.billing)));
});
