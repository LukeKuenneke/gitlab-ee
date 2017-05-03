export default {
  user: {
    avatarUrl: 'http://gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
    id: 1,
    name: 'Administrator',
    username: 'root',
  },
  createNumberRandomUsers(numberUsers) {
    const users = [];
    for (let i = 0; i < numberUsers; i = i += 1) {
      users.push(
        {
          avatarUrl: 'http://gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
          id: (i + 1),
          name: `GitLab User ${i}`,
          username: `gitlab${i}`,
        },
      );
    }
    return users;
  },
};
