const canvas = document.getElementById('game-canvas');
const ctx = canvas.getContext('2d');
const scoreElement = document.getElementById('score');
const highScoreElement = document.getElementById('high-score');
const startOverlay = document.getElementById('start-overlay');
const gameOverOverlay = document.getElementById('game-over-overlay');
const finalScoreElement = document.getElementById('final-score');
const startBtn = document.getElementById('start-btn');
const restartBtn = document.getElementById('restart-btn');

// Game Constants
const GRID_SIZE = 20;
const TILE_COUNT = canvas.width / GRID_SIZE;
const GAME_SPEED = 100; // ms per frame

// Colors (matching CSS variables)
const COLOR_SNAKE_HEAD = '#10b981'; // accent
const COLOR_SNAKE_BODY = '#34d399';
const COLOR_FOOD = '#ef4444'; // danger
const GLOW_FOOD = 'rgba(239, 68, 68, 0.6)';

// Game State
let snake = [];
let food = { x: 10, y: 10 };
let dx = 0;
let dy = -1; // Initially moving up
let score = 0;
let highScore = localStorage.getItem('snakeHighScore') || 0;
let gameLoop;
let isPlaying = false;
let changingDirection = false;

// Initialize High Score
highScoreElement.textContent = highScore;

// --- Game Functions ---

function resetGame() {
    // Start snake in the middle
    const startX = Math.floor(TILE_COUNT / 2);
    const startY = Math.floor(TILE_COUNT / 2);
    
    snake = [
        { x: startX, y: startY },
        { x: startX, y: startY + 1 },
        { x: startX, y: startY + 2 }
    ];
    
    score = 0;
    dx = 0;
    dy = -1;
    changingDirection = false;
    
    updateScore();
    placeFood();
    
    // Clear Overlays
    startOverlay.classList.add('hidden');
    gameOverOverlay.classList.add('hidden');
    
    isPlaying = true;
    
    if (gameLoop) clearInterval(gameLoop);
    gameLoop = setInterval(runGame, GAME_SPEED);
}

function runGame() {
    if (!isPlaying) return;
    
    changingDirection = false;
    
    if (checkGameOver()) {
        endGame();
        return;
    }
    
    clearCanvas();
    drawFood();
    moveSnake();
    drawSnake();
}

function clearCanvas() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
}

function drawSnake() {
    snake.forEach((part, index) => {
        // Different color for head
        ctx.fillStyle = index === 0 ? COLOR_SNAKE_HEAD : COLOR_SNAKE_BODY;
        ctx.strokeStyle = '#020617'; // very dark inline bordering
        
        // Add subtle shadow for the head
        if (index === 0) {
            ctx.shadowBlur = 10;
            ctx.shadowColor = 'rgba(16, 185, 129, 0.5)';
        } else {
            ctx.shadowBlur = 0;
        }

        // Draw slightly rounded rects by using fillRect for now (keep it performant)
        // Adjust size slightly to create gaps
        ctx.fillRect(part.x * GRID_SIZE + 1, part.y * GRID_SIZE + 1, GRID_SIZE - 2, GRID_SIZE - 2);
        ctx.strokeRect(part.x * GRID_SIZE + 1, part.y * GRID_SIZE + 1, GRID_SIZE - 2, GRID_SIZE - 2);
    });
    // Reset shadow
    ctx.shadowBlur = 0;
}

function moveSnake() {
    // Create new head
    const head = { x: snake[0].x + dx, y: snake[0].y + dy };
    snake.unshift(head);
    
    // Check food collision
    if (head.x === food.x && head.y === food.y) {
        score += 10;
        updateScore();
        placeFood();
        // Don't pop tail, so it grows
    } else {
        // Remove tail
        snake.pop();
    }
}

function placeFood() {
    food = {
        x: Math.floor(Math.random() * TILE_COUNT),
        y: Math.floor(Math.random() * TILE_COUNT)
    };
    
    // Ensure food doesn't spawn on snake
    snake.forEach(function checkFoodCollision(part) {
        if (part.x === food.x && part.y === food.y) {
            placeFood();
        }
    });
}

function drawFood() {
    ctx.fillStyle = COLOR_FOOD;
    ctx.shadowBlur = 15;
    ctx.shadowColor = GLOW_FOOD;
    
    const centerX = food.x * GRID_SIZE + GRID_SIZE / 2;
    const centerY = food.y * GRID_SIZE + GRID_SIZE / 2;
    const radius = GRID_SIZE / 2 - 2;
    
    ctx.beginPath();
    ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
    ctx.fill();
    
    // Reset shadow
    ctx.shadowBlur = 0;
}

function checkGameOver() {
    const head = snake[0];
    
    // Wall collision
    if (head.x < 0 || head.x >= TILE_COUNT || head.y < 0 || head.y >= TILE_COUNT) {
        return true;
    }
    
    // Self collision
    for (let i = 4; i < snake.length; i++) {
        if (head.x === snake[i].x && head.y === snake[i].y) {
            return true;
        }
    }
    
    return false;
}

function endGame() {
    isPlaying = false;
    clearInterval(gameLoop);
    
    finalScoreElement.textContent = score;
    gameOverOverlay.classList.remove('hidden');
    
    if (score > highScore) {
        highScore = score;
        localStorage.setItem('snakeHighScore', highScore);
        highScoreElement.textContent = highScore;
        
        // Add fun bump effect to high score
        highScoreElement.classList.remove('bump');
        void highScoreElement.offsetWidth; // trigger reflow
        highScoreElement.classList.add('bump');
    }
}

function updateScore() {
    scoreElement.textContent = score;
    
    // Add bump effect
    scoreElement.classList.remove('bump');
    void scoreElement.offsetWidth; // trigger reflow
    scoreElement.classList.add('bump');
}

// --- Event Listeners ---

document.addEventListener('keydown', (e) => {
    if (!isPlaying && document.activeElement !== startBtn && document.activeElement !== restartBtn) {
        // Optionally allow starting via Space or Enter
        if (e.key === ' ' || e.key === 'Enter') {
            resetGame();
        }
        return;
    }

    if (changingDirection) return;
    
    const key = e.key;
    const goingUp = dy === -1;
    const goingDown = dy === 1;
    const goingRight = dx === 1;
    const goingLeft = dx === -1;
    
    // Prevent default scrolling on arrow keys
    if (["ArrowUp","ArrowDown","ArrowLeft","ArrowRight"," "].indexOf(e.code) > -1) {
        e.preventDefault();
    }

    if ((key === 'ArrowLeft' || key === 'a' || key === 'A') && !goingRight) {
        dx = -1;
        dy = 0;
        changingDirection = true;
    } else if ((key === 'ArrowUp' || key === 'w' || key === 'W') && !goingDown) {
        dx = 0;
        dy = -1;
        changingDirection = true;
    } else if ((key === 'ArrowRight' || key === 'd' || key === 'D') && !goingLeft) {
        dx = 1;
        dy = 0;
        changingDirection = true;
    } else if ((key === 'ArrowDown' || key === 's' || key === 'S') && !goingUp) {
        dx = 0;
        dy = 1;
        changingDirection = true;
    }
});

startBtn.addEventListener('click', resetGame);
restartBtn.addEventListener('click', resetGame);

// Initial Canvas Setup draw
clearCanvas();
