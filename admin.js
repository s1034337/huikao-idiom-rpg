(() => {
  const STORAGE_KEY = "idiom-question-edits";
  const originalQuestions = IDIOMS.map((question) => ({
    ...question,
    _key: `${question.year}|${question.idiom}`,
  }));
  const questionEdits = JSON.parse(localStorage.getItem(STORAGE_KEY) || "{}");

  IDIOMS.forEach((question) => {
    question._key = `${question.year}|${question.idiom}`;
    if (questionEdits[question._key]) {
      Object.assign(question, questionEdits[question._key]);
    }
  });

  const style = document.createElement("style");
  style.textContent = `
    .question-admin{margin-top:34px;padding-top:24px;border-top:1px solid #ffffff18}
    .question-tools{display:grid;grid-template-columns:180px 1fr auto;gap:10px;margin:14px 0}
    .question-tools select,.question-tools input{padding:11px;border:1px solid #ffffff22;background:#0d1830;color:white;border-radius:10px}
    .question-count{color:var(--muted);align-self:center}
    .question-text{max-width:430px;line-height:1.5}
    .edit-question,.reset-question{border-radius:8px;padding:6px 10px;cursor:pointer}
    .edit-question{border:1px solid #55d6a866;background:#55d6a812;color:#7ce8c0}
    .reset-question{border:1px solid #ffd16655;background:#ffd16610;color:#ffd166;margin-left:5px}
    @media(max-width:760px){.question-tools{grid-template-columns:1fr}.question-text{min-width:260px}}
  `;
  document.head.append(style);

  const section = document.createElement("div");
  section.className = "question-admin";
  section.innerHTML = `
    <h2>📚 題庫檢查與修正</h2>
    <p class="admin-note">搜尋題目後，可立即修改正確答案與題目釋義。</p>
    <div class="question-tools">
      <select id="questionYear"><option value="all">全部年度</option></select>
      <input id="questionSearch" placeholder="搜尋成語或釋義">
      <span class="question-count" id="questionCount"></span>
    </div>
    <div class="admin-table-wrap">
      <table class="rank-table">
        <thead><tr><th>年度</th><th>正確答案</th><th>題目／釋義</th><th>管理</th></tr></thead>
        <tbody id="questionBody"></tbody>
      </table>
    </div>
  `;
  document.querySelector("#adminScreen").append(section);

  for (let year = 102; year <= 115; year += 1) {
    const option = document.createElement("option");
    option.value = year;
    option.textContent = `${year} 年`;
    document.querySelector("#questionYear").append(option);
  }

  function escapeHtml(value) {
    const node = document.createElement("div");
    node.textContent = String(value);
    return node.innerHTML;
  }

  function saveEdits() {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(questionEdits));
  }

  function drawQuestions() {
    const selectedYear = document.querySelector("#questionYear").value;
    const term = document.querySelector("#questionSearch").value.trim().toLowerCase();
    const questions = IDIOMS.filter(
      (question) =>
        (selectedYear === "all" || question.year == selectedYear) &&
        (!term ||
          question.idiom.toLowerCase().includes(term) ||
          question.meaning.toLowerCase().includes(term)),
    );

    document.querySelector("#questionCount").textContent = `共 ${questions.length} 題`;
    document.querySelector("#questionBody").innerHTML =
      questions
        .map(
          (question) => `
            <tr>
              <td>${question.year}</td>
              <td><b>${escapeHtml(question.idiom)}</b></td>
              <td class="question-text">${escapeHtml(question.meaning)}</td>
              <td>
                <button class="edit-question" data-key="${escapeHtml(question._key)}">修改</button>
                <button class="reset-question" data-key="${escapeHtml(question._key)}">還原</button>
              </td>
            </tr>`,
        )
        .join("") ||
      '<tr><td colspan="4" style="text-align:center;color:#9dadc9">找不到符合的題目</td></tr>';

    document.querySelectorAll(".edit-question").forEach((button) => {
      button.onclick = () => editQuestion(button.dataset.key);
    });
    document.querySelectorAll(".reset-question").forEach((button) => {
      button.onclick = () => resetQuestion(button.dataset.key);
    });
  }

  function editQuestion(key) {
    const question = IDIOMS.find((item) => item._key === key);
    if (!question) return;

    let idiom = prompt("修改正確答案（成語）", question.idiom);
    if (idiom === null) return;
    idiom = idiom.trim();
    if (!idiom) return alert("正確答案不可空白");

    let meaning = prompt("修改題目／釋義", question.meaning);
    if (meaning === null) return;
    meaning = meaning.trim();
    if (!meaning) return alert("題目不可空白");

    question.idiom = idiom;
    question.meaning = meaning;
    questionEdits[key] = { idiom, meaning };
    saveEdits();
    drawQuestions();
    alert("已儲存，下一場遊戲會立即套用");
  }

  function resetQuestion(key) {
    const original = originalQuestions.find((item) => item._key === key);
    const question = IDIOMS.find((item) => item._key === key);
    if (!original || !question) return;
    if (!confirm("確定還原這題的原始資料？")) return;

    question.idiom = original.idiom;
    question.meaning = original.meaning;
    delete questionEdits[key];
    saveEdits();
    drawQuestions();
  }

  document.querySelector("#questionYear").onchange = drawQuestions;
  document.querySelector("#questionSearch").oninput = drawQuestions;

  const originalAdminClick = document.querySelector("#adminBtn").onclick;
  document.querySelector("#adminBtn").onclick = (event) => {
    originalAdminClick.call(event.currentTarget, event);
    if (document.querySelector("#adminScreen").classList.contains("show")) {
      drawQuestions();
    }
  };
})();
