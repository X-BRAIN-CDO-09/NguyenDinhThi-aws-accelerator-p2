// Slide Player State
let currentSlideIndex = 0;
const slides = document.querySelectorAll('.slide');
const prevBtn = document.getElementById('prev-slide-btn');
const nextBtn = document.getElementById('next-slide-btn');
const progressBar = document.getElementById('progress-bar');
const paginationContainer = document.getElementById('pagination-dots');

// Initial setup
function initSlideshow() {
  // Generate dots
  paginationContainer.innerHTML = '';
  slides.forEach((_, index) => {
    const dot = document.createElement('div');
    dot.classList.add('pagination-dot');
    if (index === 0) dot.classList.add('active');
    dot.addEventListener('click', () => {
      goToSlide(index);
    });
    paginationContainer.appendChild(dot);
  });

  updateSlideState();
}

function updateSlideState() {
  slides.forEach((slide, index) => {
    if (index === currentSlideIndex) {
      slide.classList.add('active');
    } else {
      slide.classList.remove('active');
    }
  });

  // Update dots
  const dots = document.querySelectorAll('.pagination-dot');
  dots.forEach((dot, index) => {
    if (index === currentSlideIndex) {
      dot.classList.add('active');
    } else {
      dot.classList.remove('active');
    }
  });

  // Disable/Enable Nav buttons
  prevBtn.disabled = currentSlideIndex === 0;
  nextBtn.disabled = currentSlideIndex === slides.length - 1;

  // Update progress line
  const progressPercent = (currentSlideIndex / (slides.length - 1)) * 100;
  progressBar.style.width = `${progressPercent}%`;
}

function goToSlide(index) {
  if (index >= 0 && index < slides.length) {
    currentSlideIndex = index;
    updateSlideState();
  }
}

function nextSlide() {
  if (currentSlideIndex < slides.length - 1) {
    currentSlideIndex++;
    updateSlideState();
  }
}

function prevSlide() {
  if (currentSlideIndex > 0) {
    currentSlideIndex--;
    updateSlideState();
  }
}

// Keyboard navigation
document.addEventListener('keydown', (e) => {
  if (e.key === 'ArrowRight' || e.key === 'Space' || e.key === 'PageDown') {
    if (e.key === 'Space') e.preventDefault(); // Prevent page scroll
    nextSlide();
  } else if (e.key === 'ArrowLeft' || e.key === 'PageUp') {
    prevSlide();
  }
});

// Click handlers
nextBtn.addEventListener('click', nextSlide);
prevBtn.addEventListener('click', prevSlide);


// Theme Switcher Logic
const themeToggleBtn = document.getElementById('theme-toggle-btn');
const moonIcon = document.getElementById('moon-icon');
const sunIcon = document.getElementById('sun-icon');
const htmlEl = document.documentElement;

// Load saved theme or default to system dark
const savedTheme = localStorage.getItem('theme') || 'dark';
setTheme(savedTheme);

themeToggleBtn.addEventListener('click', () => {
  const currentTheme = htmlEl.getAttribute('data-theme');
  const newTheme = currentTheme === 'light' ? 'dark' : 'light';
  setTheme(newTheme);
});

function setTheme(theme) {
  htmlEl.setAttribute('data-theme', theme);
  localStorage.setItem('theme', theme);

  if (theme === 'light') {
    sunIcon.style.display = 'block';
    moonIcon.style.display = 'none';
  } else {
    sunIcon.style.display = 'none';
    moonIcon.style.display = 'block';
  }
}


// Slide 6 Tabs Switcher
window.switchTab = function(tabId) {
  const activeTabBtn = document.querySelector('.tab-btn.active');
  if (activeTabBtn) activeTabBtn.classList.remove('active');

  const activePanel = document.querySelector('.tab-panel.active');
  if (activePanel) activePanel.classList.remove('active');

  document.getElementById(`tab-${tabId}`).classList.add('active');
  document.getElementById(`panel-${tabId}`).classList.add('active');
};


// Slide 9 Copy Script to Clipboard
window.copyScriptText = function() {
  const speechText = document.getElementById('speech-text').innerText;
  navigator.clipboard.writeText(speechText).then(() => {
    const toast = document.getElementById('toast');
    toast.classList.add('show');
    setTimeout(() => {
      toast.classList.remove('show');
    }, 2500);
  }).catch(err => {
    console.error('Lỗi khi sao chép: ', err);
  });
};

// Initialize
initSlideshow();
