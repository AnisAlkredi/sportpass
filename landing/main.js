const yearNode = document.querySelector("#year");
if (yearNode) {
  yearNode.textContent = new Date().getFullYear();
}

const revealItems = document.querySelectorAll(".reveal");
if ("IntersectionObserver" in window && revealItems.length) {
  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add("is-visible");
          observer.unobserve(entry.target);
        }
      });
    },
    { threshold: 0.2 }
  );

  revealItems.forEach((item) => observer.observe(item));
} else {
  revealItems.forEach((item) => item.classList.add("is-visible"));
}

const heroShot = document.querySelector("#heroShot");
const shotButtons = document.querySelectorAll(".switcher button[data-shot]");

shotButtons.forEach((button) => {
  button.addEventListener("click", () => {
    if (!heroShot) return;

    shotButtons.forEach((btn) => btn.classList.remove("is-active"));
    button.classList.add("is-active");

    heroShot.style.opacity = "0.25";
    window.setTimeout(() => {
      heroShot.src = button.dataset.shot;
      heroShot.onload = () => {
        heroShot.style.opacity = "1";
      };
    }, 140);
  });
});
