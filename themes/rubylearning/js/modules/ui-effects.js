/**
 * UI Effects Module
 * Provides visual effects like confetti animations
 */

function launchConfettiAround(element) {
  if (!element) return;
  const rect = element.getBoundingClientRect();
  const originX = rect.left + rect.width / 2;
  const originY = rect.top + rect.height / 2;
  const colors = ['#f97316', '#38bdf8', '#22c55e', '#e11d48', '#6366f1'];

  // More pieces, spread further for a more celebratory effect
  for (let i = 0; i < 64; i++) {
    const piece = document.createElement('span');
    piece.className = 'confetti-piece';
    const angle = (Math.random() - 0.5) * 2 * Math.PI;
    const distance = 120 + Math.random() * 160;

    piece.style.left = `${originX}px`;
    piece.style.top = `${originY}px`;
    piece.style.backgroundColor = colors[i % colors.length];
    piece.style.setProperty('--confetti-x', `${Math.cos(angle) * distance}px`);
    piece.style.setProperty('--confetti-y', `${Math.sin(angle) * distance + 120}px`);

    document.body.appendChild(piece);

    setTimeout(() => {
      piece.remove();
    }, 1200);
  }
}

// Export for use in other modules
window.UIEffects = {
  launchConfettiAround
};
