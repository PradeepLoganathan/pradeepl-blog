// Toggle between light and dark themes
const toggleDarkMode = () => {
    const currentTheme = document.body.dataset.theme;
    const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
    document.body.dataset.theme = newTheme;
    localStorage.setItem('theme', newTheme);
  };
  
  // Apply saved theme on load
  document.addEventListener('DOMContentLoaded', () => {
    const savedTheme = localStorage.getItem('theme') || 'light';
    document.body.dataset.theme = savedTheme;
  
    // Add a toggle button
    const button = document.createElement('button');
    button.className = 'dark-mode-toggle';
    button.textContent = savedTheme === 'dark' ? 'Light Mode' : 'Dark Mode';
    button.addEventListener('click', () => {
      toggleDarkMode();
      button.textContent =
        document.body.dataset.theme === 'dark' ? 'Light Mode' : 'Dark Mode';
    });
  
    document.body.appendChild(button);
  });
  