// Smooth scrolling for anchor links
document.querySelectorAll('a[href^="#"]').forEach((anchor) => {
  anchor.addEventListener("click", function (e) {
    e.preventDefault()
    const target = document.querySelector(this.getAttribute("href"))
    if (target) {
      target.scrollIntoView({
        behavior: "smooth",
        block: "start",
      })
    }
  })
})

// Add active state to navigation links
document.addEventListener("DOMContentLoaded", () => {
  const navLinks = document.querySelectorAll(".site-nav a")
  const currentPath = window.location.pathname

  navLinks.forEach((link) => {
    if (link.getAttribute("href") === currentPath) {
      link.style.color = "#007AFF"
      link.style.borderBottom = "2px solid #007AFF"
    }
  })

  console.log("Mria theme ready.")
})
